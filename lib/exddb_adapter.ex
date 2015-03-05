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

  # Helpers

  def expect_not_exists(record) do
    model = record.__struct__
    key_type = model.__schema__(:key)
    case key_type do
      {hash, range} -> [expected: [{Atom.to_string(hash), false}, {Atom.to_string(range), false}]]
      hash -> [expected: {Atom.to_string(hash), false}]
    end
  end

  def expect_exists(record) do
    model = record.__struct__
    key = model.__schema__(:key)
    key_type = model.__schema__(:field, key)
    case {key, Exddb.Type.dump(key_type, record[key])} do
      {{hash, range}, {hash_key, range_key}} -> [expected: [{Atom.to_string(hash), hash_key}, {Atom.to_string(range), range_key}]]
      {hash, hash_key} when is_atom(hash) -> [expected: {Atom.to_string(hash), hash_key}]
    end
  end

end
