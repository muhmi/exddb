defmodule ExddbTest do
  use ExUnit.Case

  defmodule TestRepo do
    use Exddb.Repo, adapter: Exddb.Adapters.FS
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
    record = ExddbTest.TestModel.new
    {res, _reason} = ExddbTest.TestModel.__validate__(record)
    assert res != :ok
    record = ExddbTest.TestModel.new data_id: 1, data: "trololoollelelre"
    assert ExddbTest.TestModel.__validate__(record) == :ok
  end

  defmodule TestCustomTableName do
    use Exddb.Model
    @table_name "test_model"
    model do
    end
  end

  test "create/drop table" do
    assert TestRepo.create_table(TestModel) == :ok
    assert TestRepo.delete_table(TestModel) == :ok
  end

  test "schema custom table_name" do
    assert TestCustomTableName.__schema__(:table_name) == "test_model"
  end

  test "type conversions" do
    [id, name, data, number] = ExddbTest.TestModel.__dump__(ExddbTest.TestModel.new)
    assert id == {"data_id", {:s, nil}}
    assert name == {"name", {:s, "lol"}}
    assert data == {"data", {:b, "trololoo"}}
    assert number == {"number", {:n, 0}}
    dump = ExddbTest.TestModel.__dump__(ExddbTest.TestModel.new)
    assert dump == ExddbTest.TestModel.__dump__(ExddbTest.TestModel.__parse__(dump))
  end

  test "default values" do
    record = %TestModel{}
    assert record.name == "lol"
  end
end
