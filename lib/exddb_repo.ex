defmodule Exddb.Repo do
  @moduledoc ~S"""
  This module acts as a wrapper for the database, routing calls to correct backend implementations. 

  Currently `:exddb` supports DynamoDB through `erlcloud` and a limiteds backend for storing data directly to the
  local filesystem as JSON files.

  You are expected to implement a `Repo` module for your own app, for example:

      defmodule ShopApp.Repo do
        use Exddb.Repo, adapter: Exddb.Adapters.DynamoDB,
                        table_name_prefix: "myshopapp_#{to_string(Mix.env)}_"
      end

  You can then use your apps `Repo` module to make calls to the database:

      iex> ShopApp.Repo.find(ShopApp.ReceiptModel, "123-456-789")
      {:ok, %ShopApp.ReceiptModel{receipt_id: "123-456-789"", ...}}

  """
  use Behaviour
  use Exddb.ConditionalOperation

  @type t :: module
  @type return_ok_item :: {:ok, Exddb.Model.t} | {:error, :any}

  defcallback create_table(model :: Exddb.Repo.t, write_units :: integer, read_units :: integer) :: :ok | :any
  defcallback delete_table(model :: Exddb.Repo.t) :: :ok | :any

  defcallback insert(record :: Exddb.Model.t) :: return_ok_item
  defcallback update(record :: Exddb.Model.t) :: return_ok_item
  defcallback delete(record :: Exddb.Model.t) :: return_ok_item

  defcallback find(model :: Exddb.Model.t, item_id :: String.t) :: {:ok, Exddb.Model.t} | :not_found | {:error, :any}

  defmacro __using__(opts) do
    quote do

      alias Exddb.Adapter

      import Exddb.Repo

      @behaviour Exddb.Repo
      @table_name_prefix unquote(Keyword.get(opts, :table_name_prefix)) || ""
      @adapter unquote(Keyword.get(opts, :adapter) || Exddb.Adapters.DynamoDB)

      def create_table(model, write_units \\ 1, read_units \\ 1) do
        create_table(@adapter, model, table_name(model), write_units, read_units)
      end

      def delete_table(model) do
        case @adapter.delete_table(table_name(model)) do
          {:ok, _result} -> :ok
          error -> error
        end
      end

      def insert(record, conditional_op \\ nil), do: insert(@adapter, table_name(record), record, conditional_op)

      def update(record, conditional_op \\ nil), do: update(@adapter, table_name(record), record, conditional_op)

      def delete(record, conditional_op \\ nil), do: delete(@adapter, table_name(record), record, conditional_op)

      def find(model, record_id), do: find(@adapter, table_name(model), model, record_id)

      def query(model, key_conditions, options \\ []), do: query(@adapter, table_name(model), model, key_conditions, options)

      defp table_name(%{} = record), do: table_name(record.__struct__)
      defp table_name(model), do: @table_name_prefix <> model.__schema__(:table_name)

    end
  end

  @spec create_table(adapter :: Exddb.Adapter.t, model :: Exddb.Model.t, table_name :: String.t, write_units :: integer, read_units :: integer) :: :ok | {:error, :any}
  def create_table(adapter, model, table_name, write_units, read_units) do
    key = model.__schema__(:key)
    create_table(adapter, model, table_name, key, write_units, read_units)
  end

  @doc ~S"""
  Create table with hash and range key
  """
  def create_table(adapter, model, table_name, {key, range}, write_units, read_units) do
    key_type = model.__schema__(:field, key) |> Exddb.Type.dynamo_type
    range_type = model.__schema__(:field, range) |> Exddb.Type.dynamo_type
    case adapter.create_table(table_name, [{key, key_type}, {range, range_type}], {key, range}, write_units, read_units) do
      {:ok, _result}   -> :ok
      error           -> error
    end
  end

  @doc ~S"""
  Create table with hash key
  """
  def create_table(adapter, model, table_name, key, write_units, read_units) when is_atom(key) do
    key_type = model.__schema__(:field, key) |> Exddb.Type.dynamo_type
    case adapter.create_table(table_name, {key, key_type}, key, write_units, read_units) do
      {:ok, _result}   -> :ok
      error           -> error
    end
  end

  @spec insert(adapter :: Exddb.Adapter.t, table_name :: String.t, record :: Exddb.Model.t) :: return_ok_item
  def insert(adapter, table_name, record, conditional_op \\ nil) do
    if conditional_op == nil, do: conditional_op = conditional_op(not_exist: record)
    {model, key} = metadata(record)
    case model.__validate__(record) do
      :ok ->
      value = Map.get(record, key)
      case adapter.put_item(table_name, {key, value}, Exddb.Type.dump(record), conditional_op) do
        {:ok, []} -> {:ok, record}
        {:error, error} -> {:error, error}
      end
      error -> {:error, error}
    end
  end

  @spec update(adapter :: Exddb.Adapter.t, table_name :: String.t, record :: Exddb.Model.t) :: return_ok_item
  def update(adapter, table_name, record, conditional_op \\ nil) do
      if conditional_op == nil, do: conditional_op = conditional_op(exist: record)
      {model, key} = metadata(record)
      case model.__validate__(record)  do
        :ok ->
        value = Map.get(record, key)
        case adapter.put_item(table_name, {key, value}, Exddb.Type.dump(record), conditional_op) do
          {:ok, []} ->  {:ok, record}
          {:error, error} -> {:error, error}
        end
        error -> {:error, error}
      end
  end

  @spec delete(adapter :: Exddb.Adapter.t, table_name :: String.t, record :: Exddb.Model.t) :: return_ok_item
  def delete(adapter, table_name, record, conditional_op \\ nil) do
    if conditional_op == nil, do: conditional_op = conditional_op(exist: record)
    {model, key} = metadata(record)
    key_type = model.__schema__(:field, key)
    value = Map.get(record, key)
    encoded_id = Exddb.Type.dump(key_type, value)
    case adapter.delete_item(table_name, {to_string(key), encoded_id}, conditional_op) do
      {:ok, nil} -> {:ok, record}
      {:ok, []} -> {:ok, record}
      {:error, error} ->  {:error, error}
      error -> {:error, error}
    end
  end

  @spec find(adapter :: Exddb.Adapter.t, table_name :: String.t, model :: Exddb.Model.t, record_id :: :any) :: {:ok, Exddb.Model.t} | :not_found | {:error, :any}
  def find(adapter, table_name, model, record_id) do
    key = model.__schema__(:key)
    key_type = model.__schema__(:field, key)
    encoded_id = Exddb.Type.dump(key_type, record_id)
    case adapter.get_item(table_name, {to_string(key), encoded_id}) do
      {:ok, []} -> :not_found
      {:ok, item} -> {:ok, Exddb.Type.parse(item, model.new)}
    end
  end

  @spec query(adapter :: Exddb.Adapter.t, table_name :: String.t, model :: Exddb.Model.t, key_conditions :: term, options :: term) :: {:ok, :any} | {:error, :any}
  def query(adapter, table_name, model, key_conditions, options) do
    options = Keyword.put_new(options, :select, :all_attributes)
    options = Keyword.put_new(options, :consistent_read, :true)
    if not is_list(key_conditions), do: key_conditions = [key_conditions]
    key_conditions = Enum.map(key_conditions, fn({k, v}) ->
      field_type = model.__schema__(:field, k)
      {Atom.to_string(k), Exddb.Type.dump(field_type, v)}
    end)
    case adapter.query(table_name, key_conditions, options) do
      {:ok, data} -> {:ok, data |> Stream.map(&model.__parse__(&1))}
      {:error, error} -> {:error, error}
    end
  end

  defp metadata(record) do
    model = record.__struct__
    key = model.__schema__(:key)
    {model, key}
  end

end
