defmodule Exddb.Adapters.DynamoDB do

  alias Exddb.AWS.Config

  @behaviour Exddb.Adapter

  def create_table(table_name, key_spec, key, write_units, read_units, options \\ []) do
    :erlcloud_ddb2.create_table(table_name, key_spec, key, write_units, read_units, options, Config.get_config)
  end

  def delete_table(table_name, options \\ []) do
    :erlcloud_ddb2.delete_table(table_name, options, Config.get_config)
  end

  def list_tables(options \\ []) do
    :erlcloud_ddb2.list_tables options, Config.get_config
  end

  def put_item(table_name, _key, item, conditional_op) do
    :erlcloud_ddb2.put_item(table_name, item, conditional_op, Config.get_config)
  end

  def delete_item(table_name, key_spec, conditional_op) do
    :erlcloud_ddb2.delete_item(table_name, key_spec, conditional_op, Config.get_config)
  end

  def get_item(table_name, key_spec) do
    :erlcloud_ddb2.get_item(table_name, key_spec, [], Config.get_config)
  end

  def query(table_name, key_conditions, options) do
    :erlcloud_ddb2.q(table_name, key_conditions, options, Config.get_config)
  end

end
