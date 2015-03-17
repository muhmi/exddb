Code.require_file "../local_dynamo_config.exs", __ENV__.file
Code.require_file "../dynamodb_repo.exs", __ENV__.file

defmodule LocalDynamoDBTest do
 use ExUnit.Case

  use Exddb.ConditionalOperation

  setup_all do
    :ssl.start()
    :erlang.put(:aws_config, LocalDynamoConfig.get())
    :erlcloud.start()
    RemoteRepo.create_table(TestModel)
    :ok
  end

  @tag :local_dynamo
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

    {res, results} = RemoteRepo.query(TestModel, {:data_id, record.data_id})
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


end