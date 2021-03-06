
defmodule Test.RemoteRepo do
  use Exddb.Repo, adapter: Exddb.Adapters.DynamoDB,
                  table_name_prefix: "exddb_"
end

defmodule Test.TestModel do
  use Exddb.Model

  @key :data_id
  @table_name "testmodel"
  model do
    field :data_id, :string
    field :name, :string
    field :data, :binary
    field :number, :integer
    field :truth, :boolean
    field :stuff, :float, default: 3.14159265359
  end
end

defmodule Test.ModelWithHashAndRange do
  use Exddb.Model

  @key {:data_id, :timestamp}
  @table_name "testmodel_range"
  model do
    field :data_id, :string
    field :timestamp, :int
    field :content, :string
  end
end