defmodule Exddb.AWS.Config do
  
  @doc ~s"""
  Return erlcloud config for exddb
  """
  @callback get_config() :: any

  def get_config do
    impl.get_config
  end

  def impl, do: Application.get_env(:exddb, :erlcloud_config, Exddb.AWS.Config.Default)

end