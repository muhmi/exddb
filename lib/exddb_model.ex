# very much copied from https://github.com/elixir-lang/ecto/blob/master/lib/ecto/schema.ex
defmodule Exddb.Model do

  defmacro __using__(_) do
    quote do
      import Exddb.Model, only: [model: 1]
    end
  end 

  defmacro model([do: block]) do
    quote do
      Module.register_attribute(__MODULE__, :model_keys, accumulate: true)
      Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :model_fields, accumulate: true)

      try do
        import Exddb.Model
        unquote(block)
      after
        :ok
      end

      Module.eval_quoted __MODULE__, [
        Exddb.Model.__struct__(@struct_fields |> Enum.reverse), 
        Exddb.Model.__fields__(@model_fields |> Enum.reverse),
        Exddb.Model.__keys__(@model_keys |> Enum.reverse)
      ]

    end
  end

  defmacro key(name, type \\ :string, opts \\ []) do
    quote do
      Exddb.Model.__key__(__MODULE__, unquote(name), unquote(type), unquote(opts))  
    end
  end

	defmacro field(name, type \\ :string, opts \\ []) do
		quote do
			Exddb.Model.__field__(__MODULE__, unquote(name), unquote(type), unquote(opts))	
		end
	end

  def __key__(module, name, type, opts) do
    Module.put_attribute(module, :struct_fields, {name, opts[:default]})
    Module.put_attribute(module, :model_fields, {name, type})
    Module.put_attribute(module, :model_keys, {name, type})
  end

	def __field__(module, name, type, opts) do
		Module.put_attribute(module, :struct_fields, {name, opts[:default]})
    Module.put_attribute(module, :model_fields, {name, type})
	end

  def __struct__(struct_fields) do
    quote do
      defstruct unquote(Macro.escape(struct_fields))
    end
  end

  def __keys__(keys) do
    quoted = if Enum.count(keys) > 1 do
      quoted = quote do
        def __schema__(:key), do: :hash_range
      end
    else
      quoted = quote do
        def __schema__(:key), do: :hash
      end
    end
    quoted
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

end
