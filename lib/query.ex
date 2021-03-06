defmodule Exddb.Query do
	@moduledoc ~S"""

	Simple language integrated query for DynamoDB tables

  Queries are parsed to function calls to this module which return tuple like `{<<"ForumName">>, {s, <<"Amazon DynamoDB">>}}`
  which in turn erlclouds' ddb2 will understand.

  # Examples

      iex> from r in TestModel, where: r.data_id == "post"
      %Exddb.Query.QueryObject{model: TestModel, options: [], query: {"data_id", {:s, "post"}, :eq}}

      iex> from r in ModelWithHashAndRange, where: r.data_id == "post" and r.timestamp == 10
      %Exddb.Query.QueryObject{model: ModelWithHashAndRange, options: [], query: [{"data_id", {:s, "post"}, :eq}, {"timestamp", {:n, 10}, :eq}]}

  In the examples above the `query` and `options` is what will be sent to `erlcloud_ddb2`.
  Model is used to determine which DynamoDB table should be queried and how the results should be deserialized.

	"""

  defmacro __using__(_opts) do
    quote do
      import Exddb.Query
    end
  end

  @doc ~S"""
  This structure is used to store a query in the form its passed to erlcloud and metadata about the query.
  """
  defmodule QueryObject do
    defstruct model: nil, query: {}, options: []
  end

  @doc ~S"""
  Convert Elixir expression into a function call to on of the query_by_ functions.
  """
  defmacro from({:in, _, [var, module]}, opts) do
    where_expr = Keyword.get(opts, :where)
    opts = Keyword.delete(opts, :where)
    evaluate_where where_expr, var, module, opts
  end

  #
  # Compile time macro helpers
  #

  @doc ~S"""
  Query by hash and range key
  """
  def evaluate_where({:and, _, ops}, _var, module, opts) when is_list(ops) do
    # first convert the query to AST
    quoted = Enum.map(ops, fn(op) -> evaluate_query_part(op, module) end)
    # then return AST for building QueryObject struct
    quote do
      %QueryObject{query: unquote(quoted), model: unquote(module), options: unquote(opts)}
    end
  end

  @doc ~S"""
  Query by hash key, only one comparison in `:where` expression that will be converted to function call
  """
  def evaluate_where({compare_op, _, [{{:., _, [_expr_var, expr_var_field]}, _, _}, expect_field_value]}, _var, module, opts) do
    quote do
      query_by_hashkey(unquote(module), unquote(expr_var_field), unquote(expect_field_value), unquote(compare_op), unquote(opts))
    end
  end

  def evaluate_query_part({op, _, [{{:., _, [_expr_var, expr_var_field]}, _, []}, [{:.., _, [range_start, range_end]}]]}, module) do
    quote do
      build_query_part(unquote(module), unquote(expr_var_field), unquote(range_start), unquote(range_end), unquote(op))
    end
  end
  def evaluate_query_part({op, _, [{{:., _, [_expr_var, expr_var_field]}, _, []}, expect_field_value]}, module) do
    quote do
      build_query_part(unquote(module), unquote(expr_var_field), unquote(expect_field_value), unquote(op))
    end
  end

  #
  # Runtime functions
  #

  @doc ~S"""
  Query by hash key, will try to build a tuple like this `{<<"ForumName">>, {s, <<"Amazon DynamoDB">>}}`
  """
  def query_by_hashkey(module, field, value, op, opts) do
    key_field = module.schema(:key)
    case key_field do
      {hash, _range} -> %QueryObject{query: build_query_part(module, hash, value, op), model: module, options: opts}
      _ -> %QueryObject{query: build_query_part(module, field, value, op), model: module, options: opts}
    end
  end

  def build_query_part(module, field, value, op) do
    field_type = module.schema(:field, field)
    encoded_value = field_type |> Exddb.Type.dump(value)
    {Atom.to_string(field), {Exddb.Type.dynamo_type(field_type), encoded_value}, dynamize_op(op)}
  end
  def build_query_part(module, field, range_start, range_end, op) do
    field_type = module.schema(:field, field)
    encoded_value1 = field_type |> Exddb.Type.dump(range_start)
    encoded_value2 = field_type |> Exddb.Type.dump(range_end)
    {Atom.to_string(field), {{Exddb.Type.dynamo_type(field_type), encoded_value1}, {Exddb.Type.dynamo_type(field_type), encoded_value2}}, dynamize_op(op)}
  end

  def dynamize_op(:==), do: :eq
  def dynamize_op(:<=), do: :le
  def dynamize_op(:<), do: :lt
  def dynamize_op(:>), do: :gt
  def dynamize_op(:>=), do: :ge
  def dynamize_op(:in), do: :between

end