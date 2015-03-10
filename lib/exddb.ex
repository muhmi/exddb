defmodule Exddb do

  defmacro __using__(_opts) do
    quote do
      import Exddb, only: [model_set: 2]
    end
  end

  defmacro model_set(item, kw) when is_list(kw) do
    quote do
      Exddb.__model_set__(unquote(item), unquote(kw))
    end
  end

  def __model_set__(item, kw) do
    model = item.__struct__
    model.set(item, kw)
  end

end
