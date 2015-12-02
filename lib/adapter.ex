defmodule Exddb.Adapter do

  @type t :: module
  @type expect_clause_hash :: [expected: {String.t, term}]
  @type expect_clause_hash_range :: [expected: term]

  @type return_ok :: {:ok, any} | {:error, any}

  @expect_clause ~w(expect_clause_hash | expect_clause_hash_range)a

  @doc ~s"""
  Create a table with given key specification. Also sets the provisioned write and read units.
  """
  @callback create_table(table_name :: String.t, key_spec :: String.t, key :: term, write_units :: integer, read_units :: integer) :: no_return

  @doc "Delete table, does not return any status information"
  @callback delete_table(table_name :: String.t) :: no_return

  @doc "List tables, returns a list of strings"
  @callback list_tables(options :: []) :: :ok | []

  @doc "https://github.com/gleber/erlcloud/blob/master/src/erlcloud_ddb2.erl#L1688"
  @callback put_item(table_name :: String.t, key_spec :: term, item :: term, expect_clause :: term) :: return_ok

  @callback query(table_name :: String.t, key_conditions :: term, options :: term) :: return_ok

  @callback delete_item(table_name :: String.t, key_spec :: term, expect_clause :: term) :: return_ok

  @callback get_item(table_name :: String.t, key_spec :: term) :: return_ok

end
