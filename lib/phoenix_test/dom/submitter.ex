defmodule PhoenixTest.DOM.Submitter do
  @moduledoc false

  alias PhoenixTest.Element.Button
  alias PhoenixTest.FormData
  alias PhoenixTest.Html

  def find_first_submitter(%LazyHTML{} = form) do
    form
    |> Html.all("button,input[type='submit']")
    |> Enum.find_value(fn element ->
      button = Button.build(element)
      if submitter?(button), do: button
    end)
  end

  def submitter?(%Button{} = button) do
    case {button.tag, normalized_type(button.type)} do
      {"button", type} when type in ["submit", nil] -> true
      {"input", "submit"} -> true
      _ -> false
    end
  end

  def submitter_data(%Button{} = button) do
    if submitter?(button) do
      FormData.add_data(FormData.new(), button)
    else
      FormData.new()
    end
  end

  def submitter_data(_), do: FormData.new()

  def effective_method(form, submitter \\ nil) do
    method =
      override_attr(submitter, "formmethod") ||
        Map.get(form, :method) ||
        "get"

    String.downcase(method)
  end

  def effective_action(form, submitter \\ nil) do
    override_attr(submitter, "formaction") || Map.get(form, :action)
  end

  defp override_attr(%Button{} = submitter, attr) do
    if submitter?(submitter) do
      case Html.attribute(submitter.parsed, attr) do
        value when is_binary(value) ->
          trimmed = String.trim(value)
          if trimmed == "", do: nil, else: trimmed

        _ ->
          nil
      end
    end
  end

  defp override_attr(_submitter, _attr), do: nil

  defp normalized_type(nil), do: nil
  defp normalized_type(type), do: String.downcase(type)
end
