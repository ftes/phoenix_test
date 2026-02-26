defmodule PhoenixTest.DOM.Submitter do
  @moduledoc """
  Models submitter-specific behavior for form submission.

  Primary spec references:

  - WHATWG HTML: submitter concept
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#submitter
  - WHATWG HTML: submitter attribute overrides (`formmethod`, `formaction`)
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attributes-for-form-submission

  HTTP semantics reference:

  - RFC 9110: HTTP method definitions
    https://www.rfc-editor.org/rfc/rfc9110#name-method-definitions
  """

  alias PhoenixTest.Element.Button
  alias PhoenixTest.FormData
  alias PhoenixTest.Html

  @doc """
  Returns the first submitter-like control inside a form.
  """
  def find_first_submitter(%LazyHTML{} = form) do
    form
    |> Html.all("button,input[type='submit']")
    |> Enum.find_value(fn element ->
      button = Button.build(element)
      if submitter?(button), do: button
    end)
  end

  @doc """
  Returns whether a button struct represents a valid submitter control.

  Spec:
  https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#submitter
  """
  def submitter?(%Button{} = button) do
    case {button.tag, normalized_type(button.type)} do
      {"button", type} when type in ["submit", nil] -> true
      {"input", "submit"} -> true
      _ -> false
    end
  end

  @doc """
  Returns form data contributed by the submitter (`name=value`) or empty data.
  """
  def submitter_data(%Button{} = button) do
    if submitter?(button) do
      FormData.add_data(FormData.new(), button)
    else
      FormData.new()
    end
  end

  def submitter_data(_), do: FormData.new()

  @doc """
  Resolves effective HTTP method using submitter override first, then form method.
  """
  def effective_method(form, submitter \\ nil) do
    method =
      override_attr(submitter, "formmethod") ||
        Map.get(form, :method) ||
        "get"

    String.downcase(method)
  end

  @doc """
  Resolves effective action using submitter `formaction` override first.
  """
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
