# Source https://github.com/adamkittelson/ddbmodel/blob/master/test/local_dynamo_config.exs
defmodule LocalDynamoConfig do
  require Record

  Record.defrecord :aws_config, Record.extract(:aws_config, from_lib: "erlcloud/include/erlcloud_aws.hrl")

  def get do
    aws_config(ddb_scheme: 'http://', ddb_host: resolve_host, ddb_port: 8000, 
      access_key_id: 'nothing',
      secret_access_key: 'nothing'
    )
  end

  def resolve_host, do: resolve_host(System.get_env("DOCKER_HOST"))
  def resolve_host(nil),  do: 'localhost'
  def resolve_host(docker_host) when is_binary(docker_host), do: resolve_host(Regex.scan(~r/[0-9+]+\.[0-9\.]+/, docker_host))
  def resolve_host([[host]]), do: host |> String.to_char_list

end