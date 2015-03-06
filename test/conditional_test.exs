defmodule ConditionalOpTest do
  use ExUnit.Case

  use Exddb.Expect

  defmodule TestModel do
    use Exddb.Model

    @hash_key :data_id
    @table_name "testmodel"
    model do
      field :data_id, :string
      field :name, :string
     end
  end

  def test do
    item = TestModel.new data_id: 10
    assert expect(exist: item) == [expected: {"data_id", 10}]
    assert expect(not_exist: item) == [expected: {"data_id", false}]
  end


end