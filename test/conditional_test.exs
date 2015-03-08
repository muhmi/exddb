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
    item = TestModel.new data_id: "10", name: "John", last_name: "Doe"
    assert [expected: [{"data_id", "10", :eq}]] == ConditionalOperation.op_and(exist: item)
    assert [expected: [{"data_id", false}]] == ConditionalOperation.op_and(not_exist: item)
    assert [expected: [{"data_id", "10", :eq}, {"name", "some_name", :eq}], conditional_op: :and] == ConditionalOperation.op_and(exist: item, eq: item.name == "some_name")
    assert [expected: [{"data_id", "10", :eq}, {"name", "John", :eq}, {"last_name", "Doe", :eq}], conditional_op: :and] == ConditionalOperation.op_and(exist: item, eq: item.name == "John" , eq: item.last_name == "Doe")
  end

end