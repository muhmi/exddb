[![Build Status](https://travis-ci.org/muhmi/exddb.svg?branch=master)](https://travis-ci.org/muhmi/exddb)

Exddb
=====

Simple lightweight object mapper for DynamoDB and Elixir.

*This is very much a work in progress, interfaces can and probably will change.*

Opinionated Assumptions
-----------------------

The library assumes that you want to define a schema for some of the things you keep in your
awesome schema-free database.

It also argues that you want to always write the full items to DynamoDB and not take advantage of 
`UpdateItem` API.


Defining your data model
-------------------------

```elixir
defmodule MyShopApp.ReceiptModel do
  use Exddb.Model
  
  @table_name "receipts"
  @key :receipt_id
  
  # define our schema
  model do
    field :receipt_id, :string
    field :client_id, :string, null: false
    field :total, :float
    field :items, :integer
    field :processed, :boolean
    field :raw, :binary
  end

end
```

Setup a repository
-------------------------
All database operations are done through a repository module.
```elixir
defmodule MyShopApp.Repo do
  use Exddb.Repo, adapter: Exddb.Adapters.DynamoDB,
                  table_name_prefix: "shopdb_"
end
```
Using the repository:
```elixir
record = ReceiptModel.new receipt_id: "123-456", raw: "something important", processed: true
{:ok, _record} = Repo.insert(record)
```

Running tests with local DynamoDB
---------------------------------

Amazon provides [java service](http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.DynamoDBLocal.html)
that mimics DynamoDB for local development.

I run it inside a [Docker container](https://registry.hub.docker.com/u/deangiberson/aws-dynamodb-local/)

	$  docker run -d -p 8000:8000 --name dynamodb deangiberson/aws-dynamodb-local

Then run tests with the local DynamoDB

	$ mix test --only local


Running tests using AWS
-----------------------

To run tests using DynamoDB on your AWS account:

```elixir
$ mix test --only require_aws
```


