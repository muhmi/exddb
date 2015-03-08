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
      field :last_name, :string
     end
  end

  test "expect" do
    item = TestModel.new data_id: "10"
    assert [expected: {"data_id", "10"}] == ConditionalOperation.op_and(exist: item)
    assert [expected: {"data_id", false}] == ConditionalOperation.op_and(not_exist: item)

    assert  [expected: [{"data_id", "10"}, {"name", "some_name"}], conditional_op: :and] == 
            ConditionalOperation.op_and(exist: item, eq: item.name == "some_name")

    #assert [expected: [{"data_id", "10"}, {"name", "John"}, {"last_name", "Doe"}]] == ConditionalOperation.expect(exist: item, where: item.name == "John" and item.last_name == "Doe")
  end

end