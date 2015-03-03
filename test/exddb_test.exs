defmodule ExddbTest do
  use ExUnit.Case

  defmodule TestModel do
    use Exddb.Model

    @hash_key :data_id

    model do
      field :data_id, :string
      field :name, :string, default: "lol"
      field :data, :binary, default: "trololoo", null: false
    end

  end

  test "schema" do
    assert TestModel.__schema__(:fields) == [:data_id, :name, :data]
    assert TestModel.__schema__(:field, :name) == :string
    assert TestModel.__schema__(:field, :data) == :binary
    assert TestModel.__schema__(:key) == :data_id
    assert TestModel.__schema__(:field, :data_id) == :string
    assert TestModel.__schema__(:table_name) == "test_ExddbTest.TestModel"
    assert TestModel.__schema__(:null, :data_id) == false
    assert TestModel.__schema__(:null, :data) == false
    assert TestModel.__schema__(:null, :name) == true
  end

  defmodule TestCustomTableName do
    use Exddb.Model
    @table_name "test_model"
    model do
    end
  end

  test "schema custom table_name" do
    assert TestCustomTableName.__schema__(:table_name) == "test_model"
  end

  test "default values" do
    record = %TestModel{}
    assert record.name == "lol"
  end
end
