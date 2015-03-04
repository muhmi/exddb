# Again very much copied from Ecto (https://github.com/elixir-lang/ecto/blob/78ba32ca8639128c0ad36303d6d7a13ec36d2e22/lib/ecto/repo/config.ex)
defmodule Exddb.Repo do
  defmacro __using__(opts) do
  	quote bind_quoted: [opts: opts] do

  		@otp_app = Keyword.fetch!(opts, :otp_app)
  		@adapter = Application.get_env(otp_app, __MODULE__, [])[:adapter]

      unless @adapter do
        raise ArgumentError, "missing :adapter configuration in " <>
                             "config #{inspect otp_app}, #{inspect module}"
      end

      def create_table(table_name, key_spec, key, write_units, read_units) do
        @adapter.create_table(table_name, key_spec, key, write_units, read_units)
      end

      def delete_table(table_name) do
        @adapter.delete_table(table_name)
      end

      def put_item(table_name, key_spec, item) do
        @adapter.put_item(table_name, key_spec, item)
      end

      def put_item(table_name, key_spec, item, expect_not_exists) do
        @adapter.put_item(table_name, key_spec, item, expect_not_exists)
      end

      def delete_item(table_name, key_spec, expect_exists) do
        @adapter.delete_item(table_name, key_spec, expect_exists)
      end

      def get_item(table_name, key_spec) do
        @adapter.get_item(table_name, key_spec)
      end

  	end
  end
end
