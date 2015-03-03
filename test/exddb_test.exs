defmodule ExddbTest do
  use ExUnit.Case

  defmodule TestModel do
    use Exddb.Model

    model do
      key   :data_id, :string
      field :name, :string, default: "lol"
      field :data, :binary, default: nil
    end
  
  end

  test "schema" do
    assert TestModel.__schema__(:fields) == [:data_id, :name, :data]
    assert TestModel.__schema__(:field, :name) == :string
    assert TestModel.__schema__(:field, :data) == :binary
    assert TestModel.__schema__(:key) == :hash
  end

  test "default values" do
    record = %TestModel{}
    assert record.name == "lol"
  end
end
