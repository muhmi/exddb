defmodule RemoteRepoTest do
  use ExUnit.Case

  use Exddb.ConditionalOperation

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
      field :name, :string
      field :data, :binary
      field :number, :integer
      field :truth, :boolean
      field :stuff, :float, default: 3.14159265359
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
    now = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time)
    record = TestModel.new data_id: to_string(now), data: "trololoollelelre", truth: true
    {res, _} = RemoteRepo.insert(record)
    assert res == :ok
    {res, _} = RemoteRepo.insert(record)
    assert res != :ok

    record = put_in(record.number, 12)
    record = put_in(record.data, "trolollerskaters")
    record = put_in(record.stuff, 3.14159265359/2)
    record = put_in(record.name, "a fantastic name")

    {res, _} = RemoteRepo.update(record)
    assert res == :ok

    {res, _} = RemoteRepo.update(record, ConditionalOperation.expect(exist: record, where: record.name == "a fantastic name"))
    assert res == :ok

    {res, _} = RemoteRepo.update(record, ConditionalOperation.expect(exist: record, where: record.name == "some other name"))
    assert res != :ok


    {res, read_record} = RemoteRepo.find(TestModel, record.data_id)
    assert res == :ok

    assert read_record.data_id == record.data_id
    assert read_record.data == record.data
    assert read_record.number == record.number
    assert read_record.truth == record.truth
    assert read_record.stuff == record.stuff

    {res, error} = RemoteRepo.delete(record)
    if res != :ok, do: IO.puts(inspect(error))
    assert res == :ok

    {res, _} = RemoteRepo.delete(record)
    assert res != :ok
  end

end