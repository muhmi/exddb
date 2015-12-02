
defmodule LocalDynamoDBTest do
   use ExUnit.Case, async: false

  use Exddb.ConditionalOperation
  use Exddb.Query

  alias Test.RemoteRepo
  alias Test.TestModel
  alias Test.ModelWithHashAndRange

  setup_all do
    Application.put_env :exddb, :erlcloud_config, Exddb.AWS.Config.Localhost, persistent: true

    unless "exddb_testmodel" in RemoteRepo.list_tables() do
      RemoteRepo.create_table(TestModel)
      RemoteRepo.create_table(ModelWithHashAndRange)
    end

    :ok
  end

  test "list_tables" do
    list = RemoteRepo.list_tables()
    assert "exddb_testmodel" in list
    assert "exddb_testmodel_range" in list
  end

  @tag :local
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

    {res, _} = RemoteRepo.update(record, conditional_op_and(exist: record, op: record.name == "a fantastic name"))
    assert res == :ok

    {res, _} = RemoteRepo.update(record, conditional_op_and(exist: record, op: record.name == "some other name"))
    assert res != :ok

    {res, results} = RemoteRepo.query(from m in TestModel, where: m.data_id == record.data_id)
    assert res == :ok

    [data] = Enum.take(results, 1)

    assert data.data_id == record.data_id
    assert data.data == record.data
    assert data.number == record.number
    assert data.truth == record.truth
    assert data.stuff == record.stuff

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

  @tag :local
  test "range" do
    record = ModelWithHashAndRange.new data_id: new_id, timestamp: 100, content: "trololoo"
    {res, _r} = RemoteRepo.insert(record)
    assert res == :ok
    {res, _} = RemoteRepo.insert(record)
    assert res != :ok
    {res, _} = RemoteRepo.update(record)
    assert res == :ok

    {res, read_record} = RemoteRepo.find(ModelWithHashAndRange, {record.data_id, record.timestamp})
    assert res == :ok

    assert read_record.data_id == record.data_id
    assert read_record.timestamp == record.timestamp
    assert read_record.content == record.content
    {res, _} = RemoteRepo.delete(record)
    assert res == :ok
  end

  @tag :local
  test "query" do

    post_id = new_id

    for n <- 1..20 do
      record = ModelWithHashAndRange.new data_id: post_id, timestamp: n, content: "trololoo"
      {res, _record} = RemoteRepo.insert(record)
      assert res == :ok
    end

    # Query by hash key only, use limit
    {res, results} = RemoteRepo.query(
      from r in ModelWithHashAndRange,
      where: r.data_id == post_id,
      limit: 10
    )
    assert res == :ok

    assert Enum.count(results) == 10

    # Query by hash and range key
    {res, results} = RemoteRepo.query(
      from r in ModelWithHashAndRange,
      where: r.data_id == post_id and r.timestamp > 10,
      limit: 10
    )
    assert res == :ok

    assert Enum.count(results) == 10

  end

  def new_id, do: :crypto.hash(:md5, :calendar.universal_time |> inspect) |> Base.encode16

end