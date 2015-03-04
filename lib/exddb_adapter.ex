defmodule Exddb.Adapter do
  use Behaviour

  defcallback create_table(table_name :: String.t, key_spec :: String.t, key :: term, write_units :: integer, read_units :: integer) :: no_return
  defcallback delete_table(table_name :: String.t) :: no_return

  defcallback put_item(table_name :: String.t, key_spec :: term, item :: term) :: term
  defcallback put_item(table_name :: String.t, key_spec :: term, item :: term, expect_not_exists :: term) :: term
  
  defcallback delete_item(table_name :: String.t, key_spec :: term, expect_exists :: term) :: term
  
  defcallback get_item(table_name :: String.t, key_spec :: term) :: term

end
