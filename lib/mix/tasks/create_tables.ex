defmodule Mix.Tasks.Exddb.CreateTables do
  use Mix.Task

  alias Test.RemoteRepo
  alias Test.TestModel
  alias Test.ModelWithHashAndRange

  @shortdoc "Create DynamoDB tables for test"

  @moduledoc """
  Creates DynamoDB tables for testing
  ## Examples
  MIX_ENV=env mix create_tables
  """

  def run(args) do
    Mix.Task.run "app.start", args
    RemoteRepo.create_table(TestModel)
    RemoteRepo.create_table(ModelWithHashAndRange)
  end

end