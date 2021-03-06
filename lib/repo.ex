defmodule Exddb.Repo do
  @moduledoc ~S"""
  This module acts as a wrapper for the database, routing calls to correct backend implementations. 

  Currently `:exddb` supports DynamoDB through `erlcloud` and usig the local DynamoDB implementation.

  You are expected to implement a `Repo` module for your own app, for example:

      defmodule ShopApp.Repo do
        use Exddb.Repo, adapter: Exddb.Adapters.DynamoDB,
                        table_name_prefix: "myshopapp_#{to_string(Mix.env)}_"
      end

  You can then use your apps `Repo` module to make calls to the database:

      iex> ShopApp.Repo.find(ShopApp.ReceiptModel, "123-456-789")
      {:ok, %ShopApp.ReceiptModel{receipt_id: "123-456-789"", ...}}

  """
  use Exddb.ConditionalOperation

  @type t :: module
  @type return_ok_item :: {:ok, Exddb.Model.t} | {:error, :any}

  @callback create_table(model :: Exddb.Repo.t, write_units :: integer, read_units :: integer) :: :ok | :any
  @callback delete_table(model :: Exddb.Repo.t) :: :ok | :any
  @callback list_tables(options :: []) :: :any

  @callback insert(record :: Exddb.Model.t) :: return_ok_item
  @callback update(record :: Exddb.Model.t) :: return_ok_item
  @callback delete(record :: Exddb.Model.t) :: return_ok_item

  @callback find(model :: Exddb.Model.t, item_id :: String.t) :: {:ok, Exddb.Model.t} | :not_found | {:error, :any}

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

      def list_tables(options \\ []), do: @adapter.list_tables(options)

      def insert(record, conditional_op \\ nil), do: insert(@adapter, table_name(record), record, conditional_op)

      def update(record, conditional_op \\ nil), do: update(@adapter, table_name(record), record, conditional_op)

      def delete(record, conditional_op \\ nil), do: delete(@adapter, table_name(record), record, conditional_op)

      def find(model, record_id), do: find(@adapter, table_name(model), model, record_id)

      def query(%Exddb.Query.QueryObject{model: module} = query) do
        query(@adapter, table_name(module), query)
      end

      defp table_name(%{} = record), do: table_name(record.__struct__)
      defp table_name(model), do: @table_name_prefix <> model.schema(:table_name)

    end
  end

  @spec create_table(adapter :: Exddb.Adapter.t, model :: Exddb.Model.t, table_name :: String.t, write_units :: integer, read_units :: integer) :: :ok | {:error, :any}
  def create_table(adapter, model, table_name, write_units, read_units) do
    key = model.schema(:key)
    create_table(adapter, model, table_name, key, write_units, read_units)
  end

  @doc ~S"""
  Create table with hash and range key
  """
  def create_table(adapter, model, table_name, {key, range}, write_units, read_units) do
    key_type = model.schema(:field, key) |> Exddb.Type.dynamo_type
    range_type = model.schema(:field, range) |> Exddb.Type.dynamo_type
    case adapter.create_table(table_name, [{key, key_type}, {range, range_type}], {key, range}, write_units, read_units) do
      {:ok, _result}   -> :ok
      error           -> error
    end
  end

  @doc ~S"""
  Create table with hash key
  """
  def create_table(adapter, model, table_name, key, write_units, read_units) when is_atom(key) do
    key_type = model.schema(:field, key) |> Exddb.Type.dynamo_type
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
    delete(adapter, table_name, model, key, record, conditional_op)
  end
  def delete(adapter, table_name, model, {key, range}, record, conditional_op) do
    key_val = model.schema(:field, key) |> Exddb.Type.dump(Map.get(record, key))
    range_val = model.schema(:field, range) |> Exddb.Type.dump(Map.get(record, range))
    adapter.delete_item(table_name, [{to_string(key), key_val}, {to_string(range), range_val}], conditional_op) 
    |> parse_delete_resp(record)
  end
  def delete(adapter, table_name, model, key, record, conditional_op) do
    key_type = model.schema(:field, key)
    value = Map.get(record, key)
    encoded_id = Exddb.Type.dump(key_type, value)
    adapter.delete_item(table_name, {to_string(key), encoded_id}, conditional_op)
    |> parse_delete_resp(record)
  end
  def parse_delete_resp(res, record) do
    case res do
      {:ok, nil} -> {:ok, record}
      {:ok, []} -> {:ok, record}
      {:error, error} ->  {:error, error}
      error -> {:error, error}
    end
  end

  @spec find(adapter :: Exddb.Adapter.t, table_name :: String.t, model :: Exddb.Model.t, record_id :: :any) :: {:ok, Exddb.Model.t} | :not_found | {:error, :any}
  def find(adapter, table_name, model, record_id) do
    key = model.schema(:key)
    find(adapter, table_name, model, key, record_id)
  end
  def find(adapter, table_name, model, {hash, range}, {hash_id, range_val}) do
    encoded_hash = model.schema(:field, hash) |> Exddb.Type.dump(hash_id)
    encoded_range = model.schema(:field, range) |> Exddb.Type.dump(range_val)
    case adapter.get_item(table_name, [{to_string(hash), encoded_hash}, {to_string(range), encoded_range}]) do
      {:ok, []} -> :not_found
      {:ok, item} -> {:ok, Exddb.Type.parse(item, model.new)}
    end
  end
  def find(adapter, table_name, model, key, record_id) when is_atom(key) do
    key_type = model.schema(:field, key)
    encoded_id = Exddb.Type.dump(key_type, record_id)
    case adapter.get_item(table_name, {to_string(key), encoded_id}) do
      {:ok, []} -> :not_found
      {:ok, item} -> {:ok, Exddb.Type.parse(item, model.new)}
    end
  end

  @spec query(adapter :: Exddb.Adapter.t, table_name :: String.t, query :: map) :: {:ok, :any} | {:error, :any}
  def query(adapter, table_name, query) do
    options = Keyword.put_new(query.options, :select, :all_attributes)
    options = Keyword.put_new(options, :consistent_read, :true)
    model = query.model
    case adapter.query(table_name, query.query, options) do
      {:ok, data} -> {:ok, data |> Stream.map(&model.parse(&1))}
      {:error, error} -> {:error, error}
    end
  end

  defp metadata(record) do
    model = record.__struct__
    key = model.schema(:key)
    {model, key}
  end

end
