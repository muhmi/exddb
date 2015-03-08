# Again very much copied from Ecto (https://github.com/elixir-lang/ecto/blob/78ba32ca8639128c0ad36303d6d7a13ec36d2e22/lib/ecto/repo/config.ex)
defmodule Exddb.Repo do

  use Behaviour
  use Exddb.ConditionalOperation

  @type t :: module

  defcallback create_table(model :: Exddb.Repo.t, write_units :: integer, read_units :: integer) :: :ok | :any
  defcallback delete_table(model :: Exddb.Repo.t) :: :ok | :any

  defcallback insert(record :: Exddb.Model.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  defcallback update(record :: Exddb.Model.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  defcallback delete(record :: Exddb.Model.t) :: {:ok, Exddb.Model.t} | {:error, :any}

  defcallback find(model :: Exddb.Model.t, item_id :: String.t) :: {:ok, Exddb.Model.t} | :not_found | {:error, :any}

  defmacro __using__(opts) do
    quote do

      alias Exddb.Adapter

      import Exddb.Repo

      @behaviour Exddb.Repo
      @table_name_prefix unquote(Keyword.get(opts, :table_name_prefix)) || ""
      @adapter unquote(Keyword.get(opts, :adapter) || Exddb.Adapters.DynamoDB)

      def create_table(model, write_units \\ 1, read_units \\ 1) do
        key = model.__schema__(:key)
        case @adapter.create_table(table_name(model), {key, :s}, key, write_units, read_units) do
          {:ok, _result}   -> :ok
          error           -> error
        end
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

      defp table_name(%{} = record), do: table_name(record.__struct__)
      defp table_name(model), do: @table_name_prefix <> model.__schema__(:table_name)

    end
  end

  @spec insert(adapter :: Exddb.Adapter.t, table_name :: String.t, record :: Exddb.Model.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  def insert(adapter, table_name, record, conditional_op \\ nil) do
    if conditional_op == nil, do: conditional_op = ConditionalOperation.op_and(not_exist: record)
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

  @spec update(adapter :: Exddb.Adapter.t, table_name :: String.t, record :: Exddb.Model.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  def update(adapter, table_name, record, conditional_op \\ nil) do
      if conditional_op == nil, do: conditional_op = ConditionalOperation.op_and(exist: record)
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

  @spec delete(adapter :: Exddb.Adapter.t, table_name :: String.t, record :: Exddb.Model.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  def delete(adapter, table_name, record, conditional_op \\ nil) do
    if conditional_op == nil, do: conditional_op = ConditionalOperation.op_and(exist: record)
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

  @spec find(adapter :: Exddb.Adapter.t, table_name :: String.t, model :: Exddb.Model.t, record_id :: :any) :: {:ok, Exddb.Model.t} | {:error, :any}
  def find(adapter, table_name, model, record_id) do
    key = model.__schema__(:key)
    key_type = model.__schema__(:field, key)
    encoded_id = Exddb.Type.dump(key_type, record_id)
    case adapter.get_item(table_name, {to_string(key), encoded_id}) do
      {:ok, []} -> :not_found
      {:ok, item} -> {:ok, Exddb.Type.parse(item, model.new)}
    end
  end

  defp metadata(record) do
    model = record.__struct__
    key = model.__schema__(:key)
    {model, key}
  end

end
