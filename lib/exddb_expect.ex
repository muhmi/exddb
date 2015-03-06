defmodule Exddb.Expect do

  defmacro __using__(opts) do
    quote do
      import Exddb.Expect, only: [expect: 1]
    end
  end

  defmacro expect(expr) do
    build(expr, __CALLER__)
  end

  def build([exist: {var, _, _}], env) do
    quote do
      Exddb.Expect.expect_exists(unquote(Macro.var(var, env.context)))
    end
  end

  def build([not_exist: {var, _, _}], env) do
    quote do
      Exddb.Expect.expect_not_exists(unquote(Macro.var(var, env.context)))
    end
  end

  def build([exists: {:and, _, [{record, _, _}, {:==, _, [{{:., _, [{_, _, _}, field]}, _, []}, expect_value]}]}], env) do
    quote do
      Exddb.Expect.expect_exists(unquote(Macro.var(record, env.context)), [{unquote(field), unquote(expect_value)}])
    end
  end

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
    value = Map.get(record, key)
    case {key, Exddb.Type.dump(key_type, value)} do
      {{hash, range}, {hash_key, range_key}} -> [expected: [{Atom.to_string(hash), hash_key}, {Atom.to_string(range), range_key}]]
      {hash, hash_key} when is_atom(hash) -> [expected: {Atom.to_string(hash), hash_key}]
    end
  end
  def expect_exists(record, kv_list) when is_list(kv_list) do
    [expected: statement] = expect_exists(record)
    if not is_list(statement), do: statement = [statement]
    expect_exists(record, kv_list, statement)
  end
  def expect_exists(record, [{key, value}|rest], statement) do
    model = record.__struct__
    enncoded = model.__schema__(:field, key) |> Exddb.Type.dump(value)
    statement = [{Atom.to_string(key), enncoded}|statement]
    expect_exists(record, rest, statement)
  end
  def expect_exists(record, [], statement), do: [expected: Enum.reverse(statement)]

end