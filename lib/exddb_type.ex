defmodule Exddb.Type do
  @doc ~S"""
  
  Handle type conversions from DynamodDB types to Elixir and back

  http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataModel.html#DataModel.TableItemAttribute
  https://github.com/gleber/erlcloud/blob/master/src/erlcloud_ddb2.erl
    
  """
  def parse([{key, value}|rest] = record, %{} = to_struct) when is_binary(key) do
    module = to_struct.__struct__
    key = String.to_atom(key)
    value = parse(module.__schema__(:field, key), value)
    to_struct = Map.put(to_struct, key, value)
    parse(rest, to_struct)
  end
  def parse([], to_struct), do: to_struct

  def parse(:integer, v), do: v
  def parse(:float, v), do: v
  def parse(:boolean, v), do: String.to_atom(v)
  def parse(:binary, v), do: v
  def parse(:atom, v), do: String.to_atom(v)
  def parse(:string, v), do: v

  def dump(%{} = record) do
    module = record.__struct__
    for f <- module.__schema__(:fields) do
      value = Map.get(record, f)
      {Atom.to_string(f), dump(module.__schema__(:field, f), value)}
    end
  end

  def dump(:atom, v), do: Atom.to_string(v)
  def dump(:integer, v), do: {:n, v}
  def dump(:float, v), do: {:n, v}
  def dump(:boolean, v), do: {:s, Atom.to_string(v)}
  def dump(:binary, v), do: {:b, v}
  def dump(:string, v), do: {:s, v}

end
