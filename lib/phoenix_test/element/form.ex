defmodule PhoenixTest.Element.Form do
  @moduledoc """
  Internal form element wrapper used by `phoenix_test` drivers.

  DOM serialization behavior is delegated to `PhoenixTest.DOM.FormSerializer`
  (spec-aligned rules for successful controls).

  Primary spec references:

  - WHATWG HTML: form submission algorithm
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-submission-algorithm
  - WHATWG HTML: constructing the form data set
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#constructing-the-form-data-set

  Phoenix-specific behavior note:

  - `method` uses hidden `_method` override when present. That convention is
    framework behavior, not browser HTML form semantics.
  """

  alias PhoenixTest.DOM.FormSerializer
  alias PhoenixTest.Element
  alias PhoenixTest.Element.Button
  alias PhoenixTest.FormData
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[selector parsed id action method form_data submit_button]a

  @doc """
  Finds and builds a single form by selector.
  """
  def find!(html, selector) do
    html
    |> Query.find!(selector)
    |> build()
  end

  @doc """
  Finds zero/one/many forms by selector and builds wrapped form structs.
  """
  def find(html, selector) do
    html
    |> Query.find(selector)
    |> case do
      {:found, element} -> {:found, build(element)}
      {:found_many, elements} -> {:found_many, Enum.map(elements, &build/1)}
      :not_found -> :not_found
    end
  end

  @doc """
  Finds a form by one of its descendant controls.

  Form ownership logic for `form=`-associated controls is handled elsewhere by
  `PhoenixTest.DOM.FormOwner` at the call sites that need it.
  """
  def find_by_descendant!(html, descendant) do
    html
    |> Query.find_ancestor!("form", descendant_selector(descendant))
    |> build()
  end

  defp build(%LazyHTML{} = form) do
    id = Html.attribute(form, "id")
    action = Html.attribute(form, "action")
    selector = Element.build_selector(form)

    %__MODULE__{
      action: action,
      form_data: FormSerializer.to_form_data(form),
      id: id,
      method: operative_method(form),
      parsed: form,
      selector: selector,
      submit_button: Button.find_first_submit(form)
    }
  end

  @doc """
  Returns all control names currently present inside the form subtree.
  """
  def form_element_names(%__MODULE__{} = form) do
    form.parsed
    |> Html.all("[name]")
    |> Enum.map(&Html.attribute(&1, "name"))
    |> Enum.uniq()
  end

  @doc """
  Returns whether the form has a present `phx-change` binding.
  """
  def phx_change?(form) do
    form.parsed
    |> Html.attribute("phx-change")
    |> Utils.present?()
  end

  @doc """
  Returns whether the form has a present `phx-submit` binding.
  """
  def phx_submit?(form) do
    form.parsed
    |> Html.attribute("phx-submit")
    |> Utils.present?()
  end

  @doc """
  Returns whether the form has an explicit action target.
  """
  def has_action?(form), do: Utils.present?(form.action)

  defp descendant_selector(%{id: id}) when is_binary(id), do: "[id=#{inspect(id)}]"
  defp descendant_selector(%{selector: selector, text: text}), do: {selector, text}
  defp descendant_selector(%{selector: selector}), do: selector

  @doc """
  Adds submitter `name=value` contribution to serialized form data.

  Spec reference:
  https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#constructing-the-form-data-set
  """
  def put_button_data(form, nil), do: form

  def put_button_data(form, %Button{} = button) do
    Map.update!(form, :form_data, &FormData.add_data(&1, button))
  end

  defp operative_method(%LazyHTML{} = form) do
    hidden_input_method_value(form) || Html.attribute(form, "method") || "get"
  end

  defp hidden_input_method_value(form) do
    form
    |> Html.all("input[type='hidden'][name='_method']")
    |> Enum.find_value(&Html.attribute(&1, "value"))
  end
end
