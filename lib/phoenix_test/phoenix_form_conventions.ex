defmodule PhoenixTest.PhoenixFormConventions do
  @moduledoc """
  Encapsulates Phoenix-specific HTML form conventions.

  These rules are not part of browser form-submission semantics; they are
  framework conventions commonly used in Phoenix forms.
  """

  alias PhoenixTest.Html

  @doc """
  Returns the framework-operative form method.

  Phoenix forms often emulate non-GET/POST verbs by adding a hidden `_method`
  input. This function resolves that override before falling back to the form's
  `method` attribute (then `"get"`).
  """
  def operative_method(%LazyHTML{} = form) do
    hidden_input_method_value(form) || Html.attribute(form, "method") || "get"
  end

  defp hidden_input_method_value(form) do
    form
    |> Html.all("input[type='hidden'][name='_method']")
    |> Enum.find_value(&Html.attribute(&1, "value"))
  end
end
