defmodule Exddb.Model do
  @moduledoc ~S"""
  `Exddb.Model` lets you define how `:exddb` should access a given DynamoDB table.
  
  For example:

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
  
  Now we know that there is a table called `receipts` (`Exddb.Repo` will add its prefix to this name) and 
  how to convert items back and forth.

  Each `field` is assumed to allow null values, unless you specify `null: false`. 

  Note: When converting items from structs `[{key, value}, ...]` lists values containing nulls will be 
  __removed__ from resulting item.

  """

  @type t :: module

  @callback __schema__(t :: term) :: no_return
  @callback __parse__(t :: term) :: Exddb.Model.t

  defmacro __using__(_) do
    quote do
      import Exddb.Model, only: [model: 1]
       @key :hash
       @table_name Atom.to_string(Mix.env) <> "_" <> inspect(__MODULE__)
    end
  end

  defmacro model([do: block]) do
    quote do
      Module.register_attribute(__MODULE__, :model_keys, accumulate: true)
      Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :model_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :allow_null, accumulate: true)

      @behaviour Exddb.Model

      try do
        import Exddb.Model
        unquote(block)
      after
        :ok
      end

      struct_fields = @struct_fields |> Enum.reverse
      model_fields = @model_fields |> Enum.reverse

      # Generate code for the module
      Module.eval_quoted __MODULE__, [
        Exddb.Model.generate_setters,
        Exddb.Model.generate_struct(struct_fields),
        Exddb.Model.generate_field_schemas(model_fields),
        Exddb.Model.generate_key_schema(@key),
        Exddb.Model.generate_new,
        Exddb.Model.generate_table_name(@table_name),
        Exddb.Model.generate_schema_null_checks(@allow_null, @key),
        Exddb.Model.generate_type_conversions,
        Exddb.Model.generate_validation
      ]

    end
  end

  @doc ~S"""
  Define a field. For example `field :receipt_id, :string`
  """
  defmacro field(name, type \\ :string, opts \\ []) do
    quote do
      Exddb.Model.define_field(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  def define_field(module, name, :integer, []) do
    define_field(module, name, :integer, [default: 0])
  end

  def define_field(module, name, :boolean, []) do
    define_field(module, name, :boolean, [default: false])
  end

  def define_field(module, name, :float, []) do
    define_field(module, name, :float, [default: 0.0])
  end

  def define_field(module, name, type, opts) do
    Module.put_attribute(module, :struct_fields, {name, opts[:default]})
    Module.put_attribute(module, :model_fields, {name, type})
    Module.put_attribute(module, :allow_null, {name, Keyword.get(opts, :null, true)})
  end

  def generate_struct(struct_fields) do
    quote do
      defstruct unquote(Macro.escape(struct_fields))
    end
  end

  def generate_new do
    quote do
      def new(attributes \\ []) do
        defaults = __struct__
        attributes = Enum.into(attributes, Map.new)
        for k <- Map.keys(attributes) do
          if not Map.has_key?(defaults, k) do
            raise ArgumentError, "Key #{inspect k} not defined in schema #{__MODULE__}"
          end
        end
        Map.merge(defaults, attributes)
      end
    end
  end

  def generate_setters do
    quote do
      def set(item, attributes \\ []) do
        defaults = __struct__
        attributes = Enum.into(attributes, Map.new)
        for k <- Map.keys(attributes) do
          if not Map.has_key?(defaults, k) do
            raise ArgumentError, "Key #{inspect k} not defined in schema #{__MODULE__}"
          end
        end
        Map.merge(item, attributes)
      end
    end
  end

  def generate_key_schema(name) do
    quote do
      def __schema__(:key), do: unquote(name)
    end
  end

  def generate_schema_null_checks(fields, key) do
    Enum.map(fields, fn {name, allow_null} ->
      if name == key do
        quote do
          def __schema__(:null, unquote(name)), do: false
        end
      else
        quote do
          def __schema__(:null, unquote(name)), do: unquote(allow_null)
        end
      end
    end)
  end

  def generate_field_schemas(fields) do
    quoted = Enum.map(fields, fn {name, type} ->
      quote do
        def __schema__(:field, unquote(name)), do: unquote(type)
      end
    end)

    field_names = Enum.map(fields, &elem(&1, 0))

    quoted ++ [quote do
      def __schema__(:field, _), do: nil
      def __schema__(:fields), do: unquote(field_names)
    end]
  end

  def generate_type_conversions do
    quote do
      def __parse__(record), do: Exddb.Type.parse(record, new)
      def __dump__(record), do: Exddb.Type.dump(record)
    end
  end

  def generate_table_name(table_name) do
    quote do
      def __schema__(:table_name), do: unquote(table_name)
    end
  end

  def generate_validation do
    quote do
      def __validate__(%{:__struct__ => module} = record) do
        if module != __MODULE__, do: raise(ArgumentError, "Cannot validate items of type #{module} with #{__MODULE__}")
        __validate__(Map.keys(record), record)
      end
      def __validate__([:__struct__|rest], record), do: __validate__(rest, record)
      def __validate__([key|rest], record) do
        value = Map.get(record, key)
        can_be_null = __schema__(:null, key)
        if value == nil and not can_be_null do
          {:error, "#{key} cannot be null!"}
        else
          __validate__(rest, record)
        end
      end
      def __validate__([], record), do: :ok
    end
  end

end
