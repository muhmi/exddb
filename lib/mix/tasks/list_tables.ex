defmodule Mix.Tasks.Exddb.ListTables do
  use Mix.Task

  alias Test.RemoteRepo
  
  @shortdoc "Create DynamoDB tables for test"

  @moduledoc """
  Creates DynamoDB tables for testing
  ## Examples
  MIX_ENV=env mix create_tables
  """

  def run(args) do
    Mix.Task.run "app.start", args
    IO.puts(inspect(RemoteRepo.list_tables))
  end

end