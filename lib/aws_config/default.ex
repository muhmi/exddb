defmodule Exddb.AWS.Config.Default do

  @behaviour Exddb.AWS.Config

  def get_config do
    :erlcloud_aws.default_config
  end

end