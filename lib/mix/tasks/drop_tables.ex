defmodule Mix.Tasks.Exddb.DropTables do
  use Mix.Task

  alias Test.RemoteRepo
  alias Test.TestModel
  alias Test.ModelWithHashAndRange

  @shortdoc "Drop DynamoDB tables used for test"

  @moduledoc """
  Drops DynamoDB tables used for testing
  ## Examples
  MIX_ENV=env mix drop_tables
  """

  def run(args) do
    Mix.Task.run "app.start", args
    RemoteRepo.create_table(TestModel)
    RemoteRepo.create_table(ModelWithHashAndRange)
  end

end