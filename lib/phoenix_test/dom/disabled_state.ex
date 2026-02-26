defmodule PhoenixTest.DOM.DisabledState do
  @moduledoc false

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

  def control_disabled?(attrs, fieldset_stack) when is_list(attrs) and is_list(fieldset_stack) do
    disabled_attribute?(attrs) or Enum.any?(fieldset_stack)
  end

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
