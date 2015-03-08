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

  test "and" do
    item = TestModel.new data_id: "10", name: "John", last_name: "Doe"
    assert [expected: [{"data_id", "10", :eq}]] == conditional_op(exist: item)
    assert [expected: [{"data_id", :null}]] == conditional_op(not_exist: item)
    assert [expected: [{"data_id", "10", :eq}, {"name", "some_name", :eq}], conditional_op: :and] == conditional_op(exist: item, op: item.name == "some_name")
    assert [expected: [{"data_id", "10", :eq}, {"name", "John", :eq}, {"last_name", "Doe", :eq}], conditional_op: :and] == conditional_op(exist: item, op: item.name == "John" , op: item.last_name == "Doe")
  end

 defmodule LockModel do
    use Exddb.Model

    @hash_key :item_id
    @table_name "testmodel"
    model do
      field :item_id, :string
      field :status, :integer
      field :updated_at, :integer
    end
  end

  test "or" do
    lock = LockModel.new item_id: "10", status: 0, updated_at: 101010
    assert [expected: [{"item_id", :null}, {"status", 0, :eq}], conditional_op: :or] == conditional_op_or(not_exist: lock, op: lock.status == 0)
    assert [expected: [{"item_id", :null}, {"status", 0, :gt}], conditional_op: :or] == conditional_op_or(not_exist: lock, op: lock.status > 0)
  end

end