defmodule Exddb.AWS.Config.Localhost do

  @behaviour Exddb.AWS.Config

  require Record
  Record.defrecord :aws_config, Record.extract(:aws_config, from_lib: "erlcloud/include/erlcloud_aws.hrl")

  def get_config do
    aws_config(
      ddb_scheme: 'http://', ddb_host: 'localhost', ddb_port: 8000,
      access_key_id: 'nothing',
      secret_access_key: 'nothing'
    )
  end

end