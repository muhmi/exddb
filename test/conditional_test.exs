defmodule ConditionalOpTest do
  use ExUnit.Case

  use Exddb.ConditionalOperation

  defmodule TestModel do
    use Exddb.Model

    @hash_key :data_id
    @table_name "testmodel"
    model do
      field :data_id, :string
      field :name, :string
     end
  end

  test "expect" do
    item = TestModel.new data_id: "10"
    assert [expected: {"data_id", "10"}] == ConditionalOperation.expect(exist: item)
    assert [expected: {"data_id", false}] == ConditionalOperation.expect(not_exist: item)

    assert [expected: [{"data_id", "10"}, {"name", "some_name"}]] == ConditionalOperation.expect(exists: item and item.name == "some_name")
  end

end