defmodule HelperMacroTest do
  use ExUnit.Case
  use Exddb

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

  test "set" do
    item = TestModel.new data_id: "10", name: "Joe", last_name: "Foe"
    item = model_set(item, name: "Ford", last_name: "Fjord")
    assert item.last_name == "Fjord"
    assert item.name == "Ford"
  end

end