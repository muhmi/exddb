# Lots borrowed from https://github.com/elixir-lang/ecto/blob/master/lib/ecto/schema.ex
defmodule Exddb.Model do
  use Behaviour

  @type t :: module

  defcallback __schema__(t :: term) :: no_return
  defcallback __parse__(t :: term) :: Exddb.Model.t

  defmacro __using__(_) do
    quote do
      import Exddb.Model, only: [model: 1]
       @hash_key :hash
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
      @derive Access

      try do
        import Exddb.Model
        unquote(block)
      after
        :ok
      end

      struct_fields = @struct_fields |> Enum.reverse
      model_fields = @model_fields |> Enum.reverse

      Module.eval_quoted __MODULE__, [
        Exddb.Model.__struct__(struct_fields),
        Exddb.Model.__fields__(model_fields),
        Exddb.Model.__key__(@hash_key),
        Exddb.Model.__new__,
        Exddb.Model.__table_name__(@table_name),
        Exddb.Model.__nulls__(@allow_null, @hash_key),
        Exddb.Model.__convert__,
        Exddb.Model.__validate__
      ]

    end
  end

	defmacro field(name, type \\ :string, opts \\ []) do
		quote do
			Exddb.Model.__field__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
	end

  def __field__(module, name, :integer, []) do
    __field__(module, name, :integer, [default: 0])
  end

  def __field__(module, name, :boolean, []) do
    __field__(module, name, :boolean, [default: false])
  end

  def __field__(module, name, :float, []) do
    __field__(module, name, :boolean, [default: 0.0])
  end

	def __field__(module, name, type, opts) do
		Module.put_attribute(module, :struct_fields, {name, opts[:default]})
    Module.put_attribute(module, :model_fields, {name, type})
    Module.put_attribute(module, :allow_null, {name, Keyword.get(opts, :null, true)})
	end

  def __struct__(struct_fields) do
    quote do
      defstruct unquote(Macro.escape(struct_fields))
    end
  end

  def __new__ do
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

  def __key__(name) do
    quote do
      def __schema__(:key), do: unquote(name)
    end
  end

  def __nulls__(fields, key) do
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

  def __fields__(fields) do
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

  def __convert__ do
    quote do
      def __parse__(record), do: Exddb.Type.parse(record, new)
      def __dump__(record), do: Exddb.Type.dump(record)
    end
  end

  def __table_name__(table_name) do
    quote do
      def __schema__(:table_name), do: unquote(table_name)
    end
  end

  def __validate__ do
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
