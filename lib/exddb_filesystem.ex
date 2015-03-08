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

  def put_or_replace(table_name, {id_key, id_value}, item) do
    items = read_table(table_name) |>  Enum.filter(&match?(&1, id_key, id_value))
    item = item |> Enum.map(fn({k, v}) -> {k, encode(v)} end)
    items = [item | items]
    write_table(table_name, items)
    {:ok, []}
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

  def decode([{"b", v}] = _msg), do: Base.decode64!(v)
  def decode(v), do: v

  def encode({:b, v}), do: %{:b => Base.encode64(v)}
  def encode(v), do: v

  def write_table(table_name, items) do

    File.write! table_file(table_name), :jsx.encode(items, [:indent])
  end

  def table_dir, do: Application.get_env(:exddb, :fs_path) || Application.app_dir(:exddb)

  def table_file(table_name), do: "#{table_dir}/#{table_name}.json"

  def no_match?(item, key, value), do: not match?(item, key, value)

  def match?(item, key, value) do
    item = Enum.find(item, fn({k, v})-> k == key && v == value end)
    item != nil
  end

end
