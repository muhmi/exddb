defmodule Exddb.Adapter do
  use Behaviour

  @type t :: module
  @type expect_clause_hash :: [expected: {String.t, term}]
  @type expect_clause_hash_range :: [expected: term]

  @type return_ok :: {:ok, any} | {:error, any}
  
  @expect_clause ~w(expect_clause_hash | expect_clause_hash_range)a

  defcallback create_table(table_name :: String.t, key_spec :: String.t, key :: term, write_units :: integer, read_units :: integer) :: no_return
  defcallback delete_table(table_name :: String.t) :: no_return

  defcallback list_tables(options :: []) :: :ok | []

  defcallback put_item(table_name :: String.t, key_spec :: term, item :: term, expect_clause :: term) :: return_ok

  defcallback query(table_name :: String.t, key_conditions :: term, options :: term) :: return_ok
  
  defcallback delete_item(table_name :: String.t, key_spec :: term, expect_clause :: term) :: return_ok
  
  defcallback get_item(table_name :: String.t, key_spec :: term) :: return_ok


end
