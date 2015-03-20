Code.require_file "../dynamodb_repo.exs", __ENV__.file

defmodule QueryBuilderTests do
  use ExUnit.Case
  use Exddb.Query

  test "Build simple hash key comparison" do
    query = from r in TestModel, where: r.data_id == "post"
    assert %Exddb.Query.QueryObject{model: TestModel, query: {"data_id", {:s, "post"}, :eq}} == query
    query = from r in TestModel, where: r.data_id <= "post"
    assert %Exddb.Query.QueryObject{model: TestModel, query: {"data_id", {:s, "post"}, :le}} == query
    query = from r in TestModel, where: r.data_id >= "post"
    assert %Exddb.Query.QueryObject{model: TestModel, query: {"data_id", {:s, "post"}, :ge}} == query
    query = from r in TestModel, where: r.data_id < "post"
    assert %Exddb.Query.QueryObject{model: TestModel, query: {"data_id", {:s, "post"}, :lt}} == query
    query = from r in TestModel, where: r.data_id > "post"
    assert %Exddb.Query.QueryObject{model: TestModel, query: {"data_id", {:s, "post"}, :gt}} == query
  end

  test "With range key" do
    query = from r in ModelWithHashAndRange, where: r.data_id == "post" and r.timestamp < 10
    assert %Exddb.Query.QueryObject{model: ModelWithHashAndRange, query: [{"data_id", {:s, "post"}, :eq}, {"timestamp", {:n, 10}, :lt}]} == query
    query = from r in ModelWithHashAndRange, where: r.data_id == "post" and r.timestamp > 10
    assert %Exddb.Query.QueryObject{model: ModelWithHashAndRange, query: [{"data_id", {:s, "post"}, :eq}, {"timestamp", {:n, 10}, :gt}]} == query
    query = from r in ModelWithHashAndRange, where: r.data_id == "post" and r.timestamp <= 10
    assert %Exddb.Query.QueryObject{model: ModelWithHashAndRange, query: [{"data_id", {:s, "post"}, :eq}, {"timestamp", {:n, 10}, :le}]} == query
    query = from r in ModelWithHashAndRange, where: r.data_id == "post" and r.timestamp >= 10
    assert %Exddb.Query.QueryObject{model: ModelWithHashAndRange, query: [{"data_id", {:s, "post"}, :eq}, {"timestamp", {:n, 10}, :ge}]} == query
    query = from r in ModelWithHashAndRange, where: r.data_id == "post" and r.timestamp == 10
    assert %Exddb.Query.QueryObject{model: ModelWithHashAndRange, query: [{"data_id", {:s, "post"}, :eq}, {"timestamp", {:n, 10}, :eq}]} == query
  end

  test ":between" do
    query = from r in ModelWithHashAndRange, where: r.data_id == "post" and r.timestamp in [10..20]
    assert %Exddb.Query.QueryObject{model: ModelWithHashAndRange, query: [{"data_id", {:s, "post"}, :eq}, {"timestamp", {{:n, 10}, {:n, 20}}, :between}]} == query
  end
end