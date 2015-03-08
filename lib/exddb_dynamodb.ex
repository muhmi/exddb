defmodule Exddb.Adapters.DynamoDB do

  @behaviour Exddb.Adapter

  def create_table(table_name, key_spec, key, write_units, read_units) do
    :erlcloud_ddb2.create_table(table_name, key_spec, key, write_units, read_units)
  end

  def delete_table(table_name) do
    :erlcloud_ddb2.delete_table(table_name)
  end

  def put_item(table_name, _key, item) do
    :erlcloud_ddb2.put_item(table_name, item)
  end

  def put_item(table_name, _key, item, expect_not_exists) do
    :erlcloud_ddb2.put_item(table_name, item, expect_not_exists)
  end

  def delete_item(table_name, key_spec, expect_exists) do
    :erlcloud_ddb2.delete_item(table_name, key_spec, expect_exists)
  end

  def get_item(table_name, key_spec) do
    :erlcloud_ddb2.get_item(table_name, key_spec)
  end

  def query(table_name, key_conditions, options) do
    :erlcloud_ddb2.q(table_name, key_conditions, options)
  end

end
