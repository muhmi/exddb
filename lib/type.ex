defmodule Exddb.Type do
  @doc ~S"""
  
  Handle type conversions from DynamodDB types to Elixir and back

  http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataModel.html#DataModel.TableItemAttribute
  https://github.com/gleber/erlcloud/blob/master/src/erlcloud_ddb2.erl
    
  """
  def parse([{key, value}|rest], %{} = to_struct) when is_binary(key) do
    module = to_struct.__struct__
    key = String.to_atom(key)
    field_type = module.__schema__(:field, key)
    if field_type != nil do
      value = parse(field_type, value)
      to_struct = Map.put(to_struct, key, value)
    end
    parse(rest, to_struct)
  end
  def parse([], to_struct), do: to_struct

  def parse(:integer, {:n, v}), do: v
  def parse(:integer, v) when is_binary(v), do: v
  def parse(:integer, v) when is_number(v), do: v
  def parse(:int, {:n, v}), do: v
  def parse(:int, v) when is_binary(v), do: v
  def parse(:int, v) when is_number(v), do: v
  def parse(:float, {:n, v}), do: v
  def parse(:float, v) when is_binary(v), do: v
  def parse(:float, v) when is_number(v), do: v
  def parse(:boolean, {:s, v}), do: String.to_atom(v)
  def parse(:boolean, v) when is_binary(v), do: String.to_atom(v)
  def parse(:boolean, v) when is_boolean(v), do: v
  def parse(:binary, {:b, v}), do: v
  def parse(:binary, v) when is_binary(v), do: v
  def parse(:atom, v) when is_binary(v), do: String.to_atom(v)
  def parse(:atom, {:s, v}), do: String.to_atom(v)
  def parse(:string, {:s, v}), do: v
  def parse(:string, v) when is_binary(v), do: v
  # field not found in model, but stored in db
  def parse(nil, v), do: v

  def dump(%{} = record) do
    module = record.__struct__
    for f <- module.__schema__(:fields) do
      if Map.get(record, f) != nil do 
        {Atom.to_string(f), dump(module.__schema__(:field, f), Map.get(record, f))}
      end
    end |> Enum.filter(fn(kv) -> kv != nil end)
  end

  def dump(:atom, v), do: Atom.to_string(v)
  def dump(:integer, v), do: v
  def dump(:int, v), do: v
  def dump(:float, v), do: v
  def dump(:boolean, v), do: Atom.to_string(v)
  def dump(:binary, ""), do: nil
  def dump(:binary, nil), do: nil
  def dump(:binary, v), do: {:b, v}
  def dump(:string, ""), do: nil
  def dump(:string, v) when is_binary(v), do: v
  def dump(:string, v), do: to_string(v)

  def dynamo_type(:string), do: :s
  def dynamo_type(:boolean), do: :s
  def dynamo_type(:atom), do: :s
  def dynamo_type(:float), do: :n
  def dynamo_type(:integer), do: :n
  def dynamo_type(:int), do: :n
  def dynamo_type(:binary), do: :b

end
