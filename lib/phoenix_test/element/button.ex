defmodule PhoenixTest.Element.Button do
  @moduledoc false

  alias PhoenixTest.DOM.FormOwner
  alias PhoenixTest.DOM.Submitter
  alias PhoenixTest.Element
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[parsed tag id selector text type name value form_id]a

  def find!(html, selector, text) do
    html
    |> Query.find!(selector, text)
    |> build()
    |> keep_best_selector(selector)
  end

  defp keep_best_selector(button, provided_selector) do
    case provided_selector do
      "button" ->
        button

      anything_better_than_button ->
        %{button | selector: anything_better_than_button}
    end
  end

  def find_first_submit(html) do
    html
    |> Query.find("button:not([type='button']):not([type='reset'])")
    |> case do
      {:found, element} -> build(element)
      {:found_many, elements} -> elements |> Enum.at(0) |> build()
      :not_found -> nil
    end
  end

  def build(parsed) do
    tag = element_tag(parsed)
    id = Html.attribute(parsed, "id")
    name = Html.attribute(parsed, "name")
    value = Html.attribute(parsed, "value") || if name, do: ""
    selector = Element.build_selector(parsed)
    text = Html.element_text(parsed)
    type = normalize_type(tag, Html.attribute(parsed, "type"))
    form_id = Html.attribute(parsed, "form")

    %__MODULE__{
      parsed: parsed,
      tag: tag,
      id: id,
      selector: selector,
      text: text,
      type: type,
      name: name,
      value: value,
      form_id: form_id
    }
  end

  def belongs_to_form?(%__MODULE__{} = button, html) do
    Submitter.submitter?(button) and (!!button.form_id || belongs_to_ancestor_form?(button, html))
  end

  defp belongs_to_ancestor_form?(button, html) do
    case Query.find_ancestor(html, "form", {button.selector, button.text}) do
      {:found, _} -> true
      _ -> false
    end
  end

  def phx_click?(%__MODULE__{} = button), do: LiveViewBindings.phx_click?(button.parsed)

  def disabled?(%__MODULE__{} = button) do
    attr = Html.attribute(button.parsed, "disabled")

    # As a boolean attribute, something like `disabled="false"` *still* disables the button.
    # Only the complete absence of the `disabled` attribute means it is enabled.
    #
    # If you specify just `<button disabled>`, that's equivalent to `<button disabled="">`,
    # and we get the empty string as the attribute value.
    not is_nil(attr)
  end

  def has_data_method?(%__MODULE__{} = button) do
    button.parsed
    |> Html.attribute("data-method")
    |> Utils.present?()
  end

  def parent_form!(%__MODULE__{} = button, html) do
    case FormOwner.owner_form_selector(button, html) do
      nil -> Form.find_by_descendant!(html, button)
      selector -> Form.find!(html, selector)
    end
  end

  defp element_tag(parsed) do
    case Html.element(parsed) do
      {tag, _attrs, _children} -> tag
      _ -> nil
    end
  end

  defp normalize_type("button", nil), do: "submit"
  defp normalize_type(_tag, nil), do: nil
  defp normalize_type(_tag, type), do: String.downcase(type)
end
