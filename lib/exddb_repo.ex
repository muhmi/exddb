# Again very much copied from Ecto (https://github.com/elixir-lang/ecto/blob/78ba32ca8639128c0ad36303d6d7a13ec36d2e22/lib/ecto/repo/config.ex)
defmodule Exddb.Repo do

  defmacro __using__(opts) do
  	quote do

      @adapter unquote(Keyword.fetch(opts, :adapter) || Exddb.Adapters.DynamoDB)

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

  	end
  end



end
