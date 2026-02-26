defmodule PhoenixTest.Element.Field do
  @moduledoc false

  alias PhoenixTest.DOM.FormOwner
  alias PhoenixTest.Element
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings
  alias PhoenixTest.Query

  @enforce_keys ~w[parsed label id name value selector]a
  defstruct ~w[parsed label id name value selector]a

  def find_input!(html, input_selectors, label, opts) do
    field = Query.find_by_label!(html, input_selectors, label, opts)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    value = Html.attribute(field, "value")

    %__MODULE__{
      parsed: field,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def find_checkbox!(html, input_selector, label, opts) do
    field = Query.find_by_label!(html, input_selector, label, opts)

    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    value = Html.attribute(field, "value") || "on"

    %__MODULE__{
      parsed: field,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def find_hidden_uncheckbox!(html, input_selector, label, opts) do
    field = Query.find_by_label!(html, input_selector, label, opts)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    selector = Element.build_selector(field)

    hidden_input =
      hidden_uncheckbox!(%{parsed: field, selector: selector}, html, name)

    value = Html.attribute(hidden_input, "value")

    %__MODULE__{
      parsed: field,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: selector
    }
  end

  def parent_form!(field, html) do
    case FormOwner.owner_form_selector(field, html) do
      nil -> Form.find_by_descendant!(html, field)
      selector -> Form.find!(html, selector)
    end
  end

  def phx_click?(field), do: LiveViewBindings.phx_click?(field.parsed)

  def phx_value?(field), do: LiveViewBindings.phx_value?(field.parsed)

  def phx_change?(field), do: LiveViewBindings.phx_change?(field.parsed)

  def belongs_to_form?(field, html) do
    !!FormOwner.owner_form_selector(field, html)
  end

  def validate_name!(field) do
    if field.name == nil do
      raise ArgumentError, """
      Field is missing a `name` attribute:

      #{Html.raw(field.parsed)}
      """
    end
  end

  defp hidden_uncheckbox!(field, html, name) do
    form_selector = FormOwner.owner_form_selector(field, html)

    cond do
      is_nil(form_selector) ->
        Query.find!(html, "input[type='hidden'][name='#{name}']")

      hidden_input = hidden_input_in_form(html, form_selector, name) ->
        hidden_input

      true ->
        find_hidden_input_by_form_id!(html, form_selector, name)
    end
  end

  defp hidden_input_in_form(html, form_selector, name) do
    case Query.find(html, "#{form_selector} input[type='hidden'][name='#{name}']") do
      {:found, hidden_input} -> hidden_input
      _ -> nil
    end
  end

  defp find_hidden_input_by_form_id!(html, form_selector, name) do
    form = Query.find!(html, form_selector)

    case Html.attribute(form, "id") do
      nil ->
        raise ArgumentError, """
        Could not find hidden input associated to checkbox named #{inspect(name)}.
        """

      form_id ->
        Query.find!(html, "input[type='hidden'][name='#{name}'][form='#{form_id}']")
    end
  end
end
