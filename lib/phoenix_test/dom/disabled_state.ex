defmodule PhoenixTest.DOM.DisabledState do
  @moduledoc """
  Computes disabled-state semantics used by form serialization rules.

  Primary spec references:

  - WHATWG HTML: disabledness
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#concept-fe-disabled
  - WHATWG HTML: fieldset disabled + first legend exception
    https://html.spec.whatwg.org/multipage/form-elements.html#the-fieldset-element
  """

  @doc """
  Updates the fieldset-disabled stack for a child while walking a DOM tree.

  The first `<legend>` descendant of a disabled `<fieldset>` is exempt.
  """
  def next_fieldset_stack_for_child(parent_node, fieldset_stack, child_index) do
    case parent_node do
      {"fieldset", attrs, children} ->
        if disabled_attribute?(attrs) do
          [child_index != first_legend_index(children) | fieldset_stack]
        else
          fieldset_stack
        end

      _ ->
        fieldset_stack
    end
  end

  @doc """
  Returns whether a control is disabled by its own attributes or disabled ancestors.
  """
  def control_disabled?(attrs, fieldset_stack) when is_list(attrs) and is_list(fieldset_stack) do
    disabled_attribute?(attrs) or Enum.any?(fieldset_stack)
  end

  @doc """
  Returns whether an attribute list contains the boolean `disabled` attribute.
  """
  def disabled_attribute?(attrs) when is_list(attrs) do
    Enum.any?(attrs, fn {name, _value} -> name == "disabled" end)
  end

  defp first_legend_index(children) do
    children
    |> Enum.with_index()
    |> Enum.find_value(fn
      {{"legend", _attrs, _children}, index} -> index
      _ -> nil
    end)
  end
end
