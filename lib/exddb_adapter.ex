defmodule Exddb.Adapter do
  use Behaviour

  @type t :: module
  @type expect_clause_hash :: [expected: {String.t, term}]
  @type expect_clause_hash_range :: [expected: term]
  
  @expect_clause ~w(expect_clause_hash | expect_clause_hash_range)a

  defcallback create_table(table_name :: String.t, key_spec :: String.t, key :: term, write_units :: integer, read_units :: integer) :: no_return
  defcallback delete_table(table_name :: String.t) :: no_return

  defcallback put_item(table_name :: String.t, key_spec :: term, item :: term) :: term
  defcallback put_item(table_name :: String.t, key_spec :: term, item :: term, expect_clause :: term) :: term
  
  defcallback delete_item(table_name :: String.t, key_spec :: term, expect_clause :: term) :: term
  
  defcallback get_item(table_name :: String.t, key_spec :: term) :: term


end
