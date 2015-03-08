defmodule Exddb.ConditionalOperation do
  @moduledoc ~S"""
  Provide naive mappings from Elxir operations to arrays describing conditional operations that can be used with
  erlclouds DynamoDB API.
  """

  defmacro __using__(_opts) do
    quote do
      require Exddb.ConditionalOperation
      import Exddb.ConditionalOperation, only: [conditional_op: 1, conditional_op_or: 1, conditional_op_and: 1]
    end
  end

  @operators [:and, :or]

  @doc ~S"""
  Macro for buidling existence tests like:

    `conditional_op(exist: item) -> [expected: [{"key", "value", :eq}]`

  Here the struct `item` is used to find a data model definition, from which the
  key field is queried and then used to build the expression.

  """
  defmacro conditional_op(expr) do
    build(expr, __CALLER__, :and)
  end
  @doc ~S"""
  Macro for building chained conditional operations.

  For example:

    `conditional_op_or(op: item.name == "some_name", op: item.name == "another name")`
  ->
    `[expected: [{"name", "some_name", :eq}, {"name", "another name", :eq}], conditional_op: :or]`


  """
  defmacro conditional_op_or(expr) do
    build(expr, __CALLER__, :or)
  end

  @doc ~S"""
  Macro for building chained conditional operations. Does the same as `conditional_op_or/1` but
  will use `conditional_op: :and`
  """
  defmacro conditional_op_and(expr) do
    build(expr, __CALLER__, :and)
  end

  @doc ~S"""
  Build conditional operation from a list of `<<op_type>>: <<item>>.<<field>> <<operator>> <<value>>` definitios.
  Where `op_type` is one of `[:exist, :not_exist, :op]`.
  """
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
