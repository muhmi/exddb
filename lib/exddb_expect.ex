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


#  def parse([exists: {:==, [line: 31], [:data_id, {{:., [line: 31], [{:item, [line: 31], nil}, :data_id]}, [line: 31], []}]}]), do: escape(Macro.escape(expr))

#  IO.puts(inspect(unquote(Macro.escape(expr))))                     [exists: {:==, [line: 31], [:data_id, {{:., [line: 31], [{:item, [line: 31], nil}, :data_id]}, [line: 31], []}]}]
#  IO.puts(inspect(unquote(Macro.expand(expr, __CALLER__))))         [exists: false]
#  IO.puts(inspect(unquote(__CALLER__.aliases)))                     [{TestModel, Exddb.Expect.TestModel}]
#  IO.puts(inspect(unquote(__CALLER__.vars)))                        [item: nil]
#  IO.puts(inspect(unquote(Macro.var(:item, __CALLER__.context))))   %Exddb.Expect.TestModel{data: nil, data_id: 10, name: nil, number: 0, stuff: 3.14159265359, truth: false}

end
