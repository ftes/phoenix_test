defmodule PhoenixTest.DOM.FormOwner do
  @moduledoc """
  Resolves a control's form owner.

  Primary spec reference:

  - WHATWG HTML: form owner concept
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-owner

  This module applies the same precedence as browsers:

  1. Explicit `form` attribute owner (by form id).
  2. Nearest ancestor `<form>`.
  """

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.Query

  @doc """
  Returns a selector for the control's owner form, or `nil` when no owner exists.

  Spec:
  https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-owner
  """
  def owner_form_selector(control, html) do
    html = Html.parse_fragment(html)

    cond do
      form_id = explicit_form_id(control) ->
        owner_selector_by_form_id(html, form_id)

      control_selector = control_selector(control) ->
        owner_selector_by_ancestor(html, control_selector)

      true ->
        nil
    end
  end

  @doc """
  Returns the owner `<form>` node for a control, or `nil` if no owner exists.

  Spec:
  https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-owner
  """
  def owner_form(control, html) do
    case owner_form_selector(control, html) do
      nil -> nil
      selector -> Query.find!(html, selector)
    end
  end

  defp explicit_form_id(%{form_id: form_id}) when is_binary(form_id), do: form_id

  defp explicit_form_id(%{parsed: parsed}) do
    Html.attribute(parsed, "form")
  end

  defp explicit_form_id(_control), do: nil

  defp control_selector(%{selector: selector}) when is_binary(selector), do: selector
  defp control_selector(_control), do: nil

  defp owner_selector_by_form_id(html, form_id) do
    case Query.find(html, ~s(form[id=#{inspect(form_id)}])) do
      {:found, form} -> Element.build_selector(form)
      _ -> nil
    end
  end

  defp owner_selector_by_ancestor(html, control_selector) do
    case Query.find_ancestor(html, "form", control_selector) do
      {:found, form} -> Element.build_selector(form)
      _ -> nil
    end
  end
end
