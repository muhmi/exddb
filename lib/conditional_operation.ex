defmodule Exddb.ConditionalOperation do

  import Exddb.Type

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
    ops = Enum.map(list, fn(x) -> parse_operation(x, env) end)
    if Enum.count(ops) > 1 do
      quote do
        [
          {:expected, unquote(ops) |> List.flatten},
          {:conditional_op, unquote(op)}
        ]
      end
    else
      quote do
        [{:expected, unquote(ops) |> List.flatten}]
      end
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

  #
  # runtime helpers
  #

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
    key_spec = model.__schema__(:key)
    expect_exists(model, key_spec, record)
  end
  def expect_exists(model, {hash, range}, record) do
    hash_value =  model.__schema__(:field, hash) |> dump(Map.get(record, hash))
    range_value = model.__schema__(:field, range) |> dump(Map.get(record, range))
    [{Atom.to_string(hash), hash_value, :eq}, {Atom.to_string(range), range_value, :eq}]
  end
  def expect_exists(model, hash, record) do
    hash_value =  model.__schema__(:field, hash) |> dump(Map.get(record, hash))
    {Atom.to_string(hash), hash_value, :eq}
  end

end
