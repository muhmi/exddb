defmodule Exddb.Adapters.FS do

  @behaviour Exddb.Adapter

  def create_table(table_name, _key_spec, _key, _write_units, _read_units) do
    File.touch! table_file(table_name)
    {:ok, nil}
  end

  def delete_table(table_name) do
    if File.exists?(table_file(table_name)), do: File.rm!(table_file(table_name))
    {:ok, nil}
  end

  def put_item(table_name, key_spec, item) do
    put_or_replace(table_name, key_spec, item)
  end

  def put_item(table_name, {hash, range}, item, [expected: [{_, :null}, {_, :null}]]) do
    items = 
    read_table(table_name) 
    |> decode_items
    |> Enum.filter(fn(e) -> 
      not (match?(e, item, hash) and match?(e, item, range)) 
    end)
    write_table(table_name, encode_items([item|items]))
    {:ok, []}
  end

  def put_item(table_name, key_spec, item, [{:expected, [{_id, :null}]}] = _expect_not_to_exist) do
    put_new(table_name, key_spec, item)
  end

  def put_item(table_name, {key, val}, item, [{:expected, _id}|_] = expect) when is_atom(key), do: put_item(table_name, {Atom.to_string(key), val}, item, expect)
  def put_item(table_name, key_spec, item, [{:expected, _id}|_] = _expect_to_exist) do
    case get_item(table_name, key_spec) do
      {:ok, []} -> {:error, :does_not_exist}
      {:ok, _} -> put_or_replace(table_name, key_spec, item)
    end
  end

  def put_new(table_name, {key, val}, item) when is_atom(key), do: put_new(table_name, {Atom.to_string(key), val}, item)
  def put_new(table_name, key_spec, item) do
    case get_item(table_name, key_spec) do
      {:ok, []} -> put_or_replace(table_name, key_spec, item)
      {:ok, _} -> {:error, :already_exists}
    end
  end

  def delete_item(table_name, {id_key, id_value}, _expect_exists) do
    items = read_table(table_name)
    item = Enum.find(items, &match?(&1, id_key, id_value))
    items = items |> Enum.filter(&no_match?(&1, id_key, id_value))
    write_table(table_name, items)
    if item != nil do
      {:ok, nil}
    else
      {:error, :does_not_exist}
    end
  end

  def query(table_name, query, _options) when is_list(query) do
    items =
    read_table(table_name)
    |> decode_items

    sets = for {key, {_t, v}, op} <- query do
      Enum.filter(items, fn(item) -> match?(item, key, v, op) end)
    end

    [first_set, second] = sets

    items = Enum.reduce(second, [], fn(item, acc) -> 
      if Enum.find(first_set, fn(i) -> i == item end) != nil do
        acc = [item|acc]
      end
      acc
    end)

    {:ok, items}
  end
  def query(table_name, {key, {_t, v}, op}, _options) do
    items =
    read_table(table_name)
    |> decode_items
    |> Enum.filter(fn(item) -> match?(item, key, v, op) end)
    {:ok, items}
  end

  # Helpers

  def put_or_replace(table_name, {id_key, id_value}, item) do
    items = read_table(table_name) |>  Enum.filter(&match?(&1, id_key, id_value))
    item = item |> encode_item
    items = [item | items]
    write_table(table_name, items)
    {:ok, []}
  end

  def get_item(table_name, {id_key, id_value}) do
    items = read_table(table_name)
    item = Enum.find(items, &match?(&1, id_key, id_value))
    if item != nil do
      item = item |> Enum.map(fn({k, v}) -> {k, decode(v)} end)
      {:ok, item}
    else
      {:ok, []}
    end
  end

  def read_table(table_name) do
    table_path = table_file(table_name)
    if File.exists?(table_path) do
      table_path |> File.read! |> :jsx.decode
    else
      []
    end
  end

  def decode_items(items), do: Enum.map(items, &decode_item(&1))
  def decode_item(item), do: Enum.map(item, fn({k, v}) -> {k, decode(v)} end)

  def encode_items(items), do: Enum.map(items, &encode_item(&1))
  def encode_item(item), do: Enum.map(item, fn({k, v}) -> {k, encode(v)} end)

  def write_table(table_name, items) do
    # IO.puts(table_name <> inspect(items))
    File.write! table_file(table_name), :jsx.encode(items, [:indent])
  end

  def table_dir, do: Application.get_env(:exddb, :fs_path) || Application.app_dir(:exddb)

  def table_file(table_name), do: "#{table_dir}/#{table_name}.json"

  def no_match?(item, key, value), do: not match?(item, key, value)

  def match?(lhs, rhs, {key, range}) when is_list(lhs) and is_list(rhs) do
    match?(lhs, rhs, key) and match?(lhs, rhs, range)
  end
  
  def match?(lhs, rhs, key) when is_list(lhs) and is_list(rhs) and is_atom(key) do
    key = Atom.to_string(key)
    Enum.find(lhs, fn({k, _})-> k == key end) == Enum.find(rhs, fn({k, _})-> k == key end)
  end

  def match?(item, key, value), do: match?(item, key, value, :eq)
  def match?(item, key, value, :eq), do: Enum.find(item, fn({k, v})-> k == key && v == value end) != nil
  def match?(item, key, value, :lt), do: Enum.find(item, fn({k, v})-> k == key && v < value end) != nil
  def match?(item, key, value, :gt), do: Enum.find(item, fn({k, v})-> k == key && v > value end) != nil
  def match?(item, key, value, :le), do: Enum.find(item, fn({k, v})-> k == key && v <= value end) != nil
  def match?(item, key, value, :ge), do: Enum.find(item, fn({k, v})-> k == key && v >= value end) != nil


  def decode([{"b", v}] = _msg), do: Base.decode64!(v)
  def decode(v), do: v

  def encode({:b, v}), do: %{:b => Base.encode64(v)}
  def encode(v), do: v

end
