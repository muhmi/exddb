defmodule Exddb.Adapters.DynamoDB do

  alias Exddb.AWSConfig

  @behaviour Exddb.Adapter

  def create_table(table_name, key_spec, key, write_units, read_units, options \\ []) do
    :erlcloud_ddb2.create_table(table_name, key_spec, key, write_units, read_units, options, AWSConfig.get)
  end

  def delete_table(table_name, options \\ []) do
    :erlcloud_ddb2.delete_table(table_name, options, AWSConfig.get)
  end

  def list_tables(options \\ []) do
    :erlcloud_ddb2.list_tables options, AWSConfig.get
  end

  def put_item(table_name, _key, item, conditional_op) do
    :erlcloud_ddb2.put_item(table_name, item, conditional_op, AWSConfig.get)
  end

  def delete_item(table_name, key_spec, conditional_op) do
    :erlcloud_ddb2.delete_item(table_name, key_spec, conditional_op, AWSConfig.get)
  end

  def get_item(table_name, key_spec) do
    :erlcloud_ddb2.get_item(table_name, key_spec, [], AWSConfig.get)
  end

  def query(table_name, key_conditions, options) do
    :erlcloud_ddb2.q(table_name, key_conditions, options, AWSConfig.get)
  end

end
