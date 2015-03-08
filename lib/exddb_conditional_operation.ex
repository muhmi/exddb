defmodule Exddb.ConditionalOperation do

  defmacro __using__(_opts) do
    quote do
      require Exddb.ConditionalOperation
      import Exddb.ConditionalOperation, only: [conditional_op: 1, conditional_op_or: 1, conditional_op_and: 1]
    end
  end

  @operators [:and, :or]

  defmacro conditional_op(expr) do
    build(expr, __CALLER__, :and)
  end
  defmacro conditional_op_or(expr) do
    build(expr, __CALLER__, :or)
  end
  defmacro conditional_op_and(expr) do
    build(expr, __CALLER__, :and)
  end

  def build(list, env, op) do
    if Enum.count(list) > 1 do
      [
        {:expected, Enum.map(list, fn(x) -> parse_operation(x, env) end)},
        {:conditional_op, op}
      ]
    else
      [
        {:expected, Enum.map(list, fn(x) -> parse_operation(x, env) end)}
      ]
    end
  end

  def parse_operation({:exist, {var, _, _}}, env) do
    quote do: Exddb.ConditionalOperation.expect_exists(unquote(Macro.var(var, env.context)))
  end
  def parse_operation({:not_exist, {var, _, _}}, env) do
    quote do: Exddb.ConditionalOperation.expect_not_exists(unquote(Macro.var(var, env.context)))
  end
  def parse_operation({:op, {:==, _, [{{:., _, [{_var, _, _}, field]}, _, _}, expect_value]}}, _env) do
    quote do: {unquote(Atom.to_string(field)), unquote(expect_value), :eq}
  end
  def parse_operation({:op, {:!=, _, [{{:., _, [{_var, _, _}, field]}, _, _}, expect_value]}}, _env) do
    quote do: {unquote(Atom.to_string(field)), unquote(expect_value), :ne}
  end
  def parse_operation({:op, {:>, _, [{{:., _, [{_var, _, _}, field]}, _, _}, expect_value]}}, _env) do
    quote do: {unquote(Atom.to_string(field)), unquote(expect_value), :gt}
  end
  def parse_operation({:op, {:<, _, [{{:., _, [{_var, _, _}, field]}, _, _}, expect_value]}}, _env) do
    quote do: {unquote(Atom.to_string(field)), unquote(expect_value), :lt}
  end
  def parse_operation({:op, {:>=, _, [{{:., _, [{_var, _, _}, field]}, _, _}, expect_value]}}, _env) do
    quote do: {unquote(Atom.to_string(field)), unquote(expect_value), :ge}
  end
  def parse_operation({:op, {:<=, _, [{{:., _, [{_var, _, _}, field]}, _, _}, expect_value]}}, _env) do
    quote do: {unquote(Atom.to_string(field)), unquote(expect_value), :le}
  end

  # runtime helpers

  def expect_not_exists(record) do
    model = record.__struct__
    key_type = model.__schema__(:key)
    case key_type do
      {hash, range} -> [[{Atom.to_string(hash), :null}, {Atom.to_string(range), :null}]]
      hash -> {Atom.to_string(hash), :null}
    end
  end

  def expect_exists(record) do
    model = record.__struct__
    key = model.__schema__(:key)
    key_type = model.__schema__(:field, key)
    value = Map.get(record, key)
    case {key, Exddb.Type.dump(key_type, value)} do
      {{hash, range}, {hash_key, range_key}} -> [{Atom.to_string(hash), hash_key, :eq}, {Atom.to_string(range), range_key, :eq}]
      {hash, hash_key} when is_atom(hash) -> {Atom.to_string(hash), hash_key, :eq}
    end
  end

end
