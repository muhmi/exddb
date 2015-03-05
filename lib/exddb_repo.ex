# Again very much copied from Ecto (https://github.com/elixir-lang/ecto/blob/78ba32ca8639128c0ad36303d6d7a13ec36d2e22/lib/ecto/repo/config.ex)
defmodule Exddb.Repo do

  use Behaviour

  @type t :: module

  defcallback create_table(model :: Exddb.Repo.t, write_units :: integer, read_units :: integer) :: :ok | :any
  defcallback delete_table(model :: Exddb.Repo.t) :: :ok | :any

  defcallback insert(record :: Exddb.Repo.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  defcallback update(record :: Exddb.Repo.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  defcallback delete(record :: Exddb.Repo.t) :: {:ok, Exddb.Model.t} | {:error, :any}

  defcallback find(model :: Exddb.Model.t, item_id :: String.t) :: {:ok, Exddb.Model.t} | :not_found | {:error, :any}

  defmacro __using__(opts) do
  	quote do

      alias Exddb.Adapter

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
          {:ok, _result}   -> :ok
          error           -> error
        end
      end

      def insert(record) do
        model = record.__struct__
        key = model.__schema__(:key)

        case model.__validate__(record) do
          :ok ->
          case @adapter.put_item(table_name(model), {key, record[key]}, Exddb.Type.dump(record), Adapter.expect_not_exists(record)) do
            {:ok, _result}   -> {:ok, record}
            error           -> {:error, error}
          end
          error -> {:error, error}
        end

      end

      def update(record) do

        model = record.__struct__
        key = model.__schema__(:key)

        case model.__validate__(record)  do
          :ok ->
          case @adapter.put_item(table_name(model), {key, record[key]}, Exddb.Type.dump(record), Adapter.expect_exists(record)) do
            {:ok, _result}   -> {:ok, record}
            error           -> {:error, error}
          end
          error -> {:error, error}
        end

      end

      def delete(record), do: {:error, :not_implemented}

      def find(model, record_id) do
        key = model.__schema__(:key)
        key_type = model.__schema__(:field, key)
        encoded_id = Exddb.Type.dump(key_type, record_id)
        case @adapter.get_item(table_name(model), {to_string(key), encoded_id}) do
          {:ok, []}     -> :not_found
          {:ok, item}   -> {:ok, Exddb.Type.parse(item, model.new)}
        end
      end

      defp table_name(model), do: @table_name_prefix <> model.__schema__(:table_name)

  	end
  end

end
