defmodule RemoteRepoTest do
  use ExUnit.Case

  defmodule RemoteRepo do
    use Exddb.Repo, adapter: Exddb.Adapters.DynamoDB,
                    table_name_prefix: "exddb_"
  end

  defmodule TestModel do
    use Exddb.Model

    @hash_key :data_id
    @table_name "testmodel"
    model do
      field :data_id, :string
      field :name, :string, default: "lol"
      field :data, :binary, default: "trololoo", null: false
      field :number, :integer
      field :truth, :boolean
    end
  end

  setup_all do
    # todo: write some prepare/teardown mix task
    :ssl.start()
    :erlcloud.start()
    RemoteRepo.create_table(TestModel)
    :ok
  end

  test "crud" do
    record = TestModel.new data_id: "112121", data: "trololoollelelre"
    {res, _} = RemoteRepo.insert(record)
    assert res == :ok
    {res, _} = RemoteRepo.insert(record)
    assert res != :ok

    record = put_in(record.number, 12)
    record = put_in(record.data, "trolollerskaters")

    {res, _} = RemoteRepo.update(record)
    assert res == :ok

    {res, read_record} = RemoteRepo.find(TestModel, record.data_id)
    assert res == :ok

    assert read_record.data_id == record.data_id
    assert read_record.data == record.data
    assert read_record.number == record.number
    assert read_record.truth == record.truth

    {res, _} = RemoteRepo.delete(record)
    assert res == :ok

    {res, _} = RemoteRepo.delete(record)
    assert res != :ok
  end

end