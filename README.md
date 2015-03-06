Exddb
=====

Simple and lightweight object mapper for DynamoDB and Elixir

Features:
- Basic CRUD operations and find
- Can use DynamoDB or local file system for storing data
- Conditional operations

TODO:
- Range keys
- Query support =)


Defining your data model
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

Setup a repository
-------------------------
All database operations are done through a repository module.
```elixir
defmodule RemoteRepo do
  use Exddb.Repo, adapter: Exddb.Adapters.DynamoDB,
                  table_name_prefix: "exddb_"
end
```
Using the repository:
```elixir
record = TestModel.new data_id: to_string(now), data: "something important", truth: true
{:ok, _record} = RemoteRepo.insert(record)
```

Note: You can define multiple repositories in your app.

Conditional operations
-------------------------

Currently only a few simple condiotional operations are supported with insert, update and delete.

```elixir
record = TestModel.new data_id: to_string(now), data: "something important", truth: true
{:ok, _record} = RemoteRepo.insert(record)

# Is equivalent to:

record = TestModel.new data_id: to_string(now), data: "something important", truth: true
{:ok, _record} = RemoteRepo.insert(record, ConditionalOperation.expect(not_exist: record))

# -> Ceates a conditional operation that checks that there is no record with the key data_id you are trying to insert

# Another example:

iex> RemoteRepo.update(record, ConditionalOperation.expect(exist: record, where: record.name == "some other name"))
{:error, {"ConditionalCheckFailedException", "The conditional request failed"}}


```