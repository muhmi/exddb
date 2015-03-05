defmodule ExddbTest do
  use ExUnit.Case

  defmodule LocalRepo do
    use Exddb.Repo, adapter: Exddb.Adapters.FS, 
                    table_name_prefix: "exddb_"
  end

  defmodule TestModel do
    use Exddb.Model

    @hash_key :data_id

    model do
      field :data_id, :string
      field :name, :string, default: "lol"
      field :data, :binary, default: "trololoo", null: false
      field :number, :integer
    end

  end

  #setup do
  #  LocalRepo.delete_table(TestModel)
  #end

  test "schema" do
    assert TestModel.__schema__(:fields) == [:data_id, :name, :data, :number]
    assert TestModel.__schema__(:field, :name) == :string
    assert TestModel.__schema__(:field, :data) == :binary
    assert TestModel.__schema__(:key) == :data_id
    assert TestModel.__schema__(:field, :data_id) == :string
    assert TestModel.__schema__(:table_name) == "test_ExddbTest.TestModel"
    assert TestModel.__schema__(:null, :data_id) == false
    assert TestModel.__schema__(:null, :data) == false
    assert TestModel.__schema__(:null, :name) == true
  end

  test "validate" do
    record = TestModel.new
    {res, _reason} = TestModel.__validate__(record)
    assert res != :ok
    record = TestModel.new data_id: 1, data: "trololoollelelre"
    assert TestModel.__validate__(record) == :ok
  end

  defmodule TestCustomTableName do
    use Exddb.Model
    @table_name "test_model"
    model do
    end
  end

  test "create/drop table" do
    assert LocalRepo.create_table(TestModel) == :ok
    assert LocalRepo.delete_table(TestModel) == :ok
  end

  test "schema custom table_name" do
    assert TestCustomTableName.__schema__(:table_name) == "test_model"
  end

  test "type conversions" do
    [id, name, data, number] = TestModel.__dump__(TestModel.new(data_id: "some_id"))
    assert id == {"data_id", "some_id"}
    assert name == {"name", "lol"}
    assert data == {"data", {:b, "trololoo"}}
    assert number == {"number", 0}
    dump = TestModel.__dump__(TestModel.new(data_id: "my_id"))
    assert dump == TestModel.__dump__(TestModel.__parse__(dump))
  end

  test "default values" do
    record = %TestModel{}
    assert record.name == "lol"
  end

  test "binary" do
    record = TestModel.new data_id: "111", data: "trololoollelelre"
    {res, _} = LocalRepo.insert(record)
    assert res == :ok
    {res, read_record} = LocalRepo.find(TestModel, record.data_id)
    assert res == :ok
    assert record.data == read_record.data
    assert record.data_id == read_record.data_id
    assert record.number == read_record.number
  end

  test "insert" do
    record = TestModel.new data_id: "112121", data: "trololoollelelre"
    {res, _} = LocalRepo.insert(record)
    assert res == :ok
    {res, _} = LocalRepo.insert(record)
    assert res != :ok
    {res, _} = LocalRepo.delete(record)
    assert res == :ok
  end

  test "update" do
    record = TestModel.new data_id: "2", data: "trololoollelelre"
    {res, _} = LocalRepo.update(record)
    assert res != :ok
    {res, _} = LocalRepo.insert(record)
    assert res == :ok
    {res, _} = LocalRepo.update(record)
    assert res == :ok
  end

  test "delete" do
    record = TestModel.new data_id: "1", data: "trololoollelelre"
    {res, _} = LocalRepo.insert(record)
    assert res == :ok
    {res, _} = LocalRepo.delete(record)
    assert res == :ok
    {res, _} = LocalRepo.delete(record)
    assert res != :ok
  end

end