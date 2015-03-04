# Again very much copied from Ecto (https://github.com/elixir-lang/ecto/blob/78ba32ca8639128c0ad36303d6d7a13ec36d2e22/lib/ecto/repo/config.ex)
defmodule Exddb.Repo do

  use Behaviour

  @type t :: module

  defcallback create_table(model :: Exddb.Repo.t, write_units :: integer, read_units :: integer) :: :ok | :any
  defcallback delete_table(model :: Exddb.Repo.t) :: :ok | :any

  defcallback insert(record :: Exddb.Repo.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  defcallback update(record :: Exddb.Repo.t) :: {:ok, Exddb.Model.t} | {:error, :any}
  defcallback delete(record :: Exddb.Repo.t) :: {:ok, Exddb.Model.t} | {:error, :any}

  defcallback find(item_id :: String.t) :: {:ok, Exddb.Model.t} | :not_found | {:error, :any}

  defmacro __using__(opts) do
  	quote do

      alias Exddb.Adapter

      @behaviour Exddb.Repo
      @adapter unquote(Keyword.get(opts, :adapter) || Exddb.Adapters.DynamoDB)

      def create_table(model, write_units \\ 1, read_units \\ 1) do
        key = model.__schema__(:key)
        table_name = model.__schema__(:table_name)
        case @adapter.create_table(table_name, {key, :s}, key, write_units, read_units) do
          {:ok, _result}   -> :ok
          error           -> error
        end
      end

      def delete_table(model) do
        table_name = model.__schema__(:table_name)
        case @adapter.delete_table(table_name) do
          {:ok, _result}   -> :ok
          error           -> error
        end
      end

      def insert(record) do
        model = record.__struct__
        key = model.__schema__(:key)
        table_name = model.__schema__(:table_name)

        case model.__validate__(record) do
          :ok ->
          case @adapter.put_item(table_name, {key, model[key]}, Exddb.Type.dump(record), Adapter.expect_not_exists(key)) do
            {:ok, _}   -> {:ok, record}
            error           -> {:error, error}
          end
          error -> {:error, error}
        end
      end


  	end
  end



end
