Exddb
=====

Simple and lightweidht object mapper for DynamoDB.

Supports:

- Basic CRUD operations and find
- Can use DynamoDB or local file system for storing data

TODO

- Range keys

- Query support

- Support for using custom constraints insert/update/delete
  http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_ExpectedAttributeValue.html 


Usage
-------------------------

```elixir
  defmodule TestModel do
    use Exddb.Model

    @hash_key :data_id
    @table_name "testmodel"
    model do
      field :data_id, :string
      field :name, :string, default: "lol"
      field :data, :binary, default: <<0, 1, 3, 4>>, null: false
      field :number, :integer
      field :truth, :boolean
      field :stuff, :float, default: 3.14159265359
    end
  end
```

All database operations are done through a repository module.

You need to build one for your self:

```elixir
  defmodule RemoteRepo do
    use Exddb.Repo, adapter: Exddb.Adapters.DynamoDB,
                    table_name_prefix: "exddb_"
  end
```

```elixir
  record = TestModel.new data_id: to_string(now), data: "trololoollelelre", truth: true
  {:ok, _record} = RemoteRepo.insert(record)
```
