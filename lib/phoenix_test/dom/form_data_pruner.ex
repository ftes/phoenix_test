defmodule PhoenixTest.DOM.FormDataPruner do
  @moduledoc """
  Prunes pending form data against the currently rendered DOM.

  This prevents stale values from being submitted when controls were removed
  before submit, while preserving controls associated via the `form` attribute.
  """

  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData
  alias PhoenixTest.Html

  @doc """
  Keeps only entries whose `name` still exists in the owner form subtree or as
  an associated `[form="<form-id>"]` control in the current DOM.
  """
  def prune_removed_fields(%FormData{} = form_data, %Form{} = form, html) do
    valid_names =
      form
      |> valid_form_element_names(html)
      |> MapSet.new()

    FormData.filter(form_data, fn %{name: name} ->
      MapSet.member?(valid_names, name)
    end)
  end

  @doc """
  Returns all currently valid field names for this form in the given DOM.
  """
  def valid_form_element_names(%Form{} = form, html) do
    Enum.uniq(Form.form_element_names(form) ++ associated_form_element_names(form, html))
  end

  defp associated_form_element_names(%Form{id: nil}, _html), do: []

  defp associated_form_element_names(%Form{id: form_id}, html) do
    html
    |> Html.parse_fragment()
    |> Html.all(~s([name][form="#{form_id}"]))
    |> Enum.map(&Html.attribute(&1, "name"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end
end
