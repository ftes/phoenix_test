defmodule PhoenixTest.DOM.SuccessfulControls do
  @moduledoc """
  Extracts successful form-control entries from a parsed `<form>`.

  Primary spec references:

  - WHATWG HTML: constructing the form data set
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#constructing-the-form-data-set
  - WHATWG HTML: form submission algorithm
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#form-submission-algorithm

  Secondary reference:

  - MDN FormData
    https://developer.mozilla.org/en-US/docs/Web/API/FormData

  This module is intentionally focused on serialization semantics (successfulness,
  disabledness, default values). It does not model transport or event mechanics.
  """

  alias PhoenixTest.DOM.DisabledState
  alias PhoenixTest.Html

  @simple_value_types MapSet.new(~w(date datetime-local email month number password range search tel text time url week))
  @excluded_input_types MapSet.new(~w(button file image reset submit))

  @doc """
  Returns ordered `{name, value}` entries for controls that are successful.

  Spec:
  https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#constructing-the-form-data-set
  """
  def entries(%LazyHTML{} = form) do
    form
    |> Html.element()
    |> case do
      nil -> []
      tree -> tree |> walk([], []) |> Enum.reverse()
    end
  end

  defp walk({tag, attrs, children} = node, fieldset_stack, acc) do
    acc =
      tag
      |> control_entries(attrs, children, fieldset_stack)
      |> prepend_entries(acc)

    children
    |> Enum.with_index()
    |> Enum.reduce(acc, fn {child, child_index}, acc ->
      child_fieldset_stack =
        DisabledState.next_fieldset_stack_for_child(node, fieldset_stack, child_index)

      walk(child, child_fieldset_stack, acc)
    end)
  end

  defp walk(_node, _fieldset_stack, acc), do: acc

  defp prepend_entries(entries, acc) do
    Enum.reduce(entries, acc, fn entry, acc -> [entry | acc] end)
  end

  defp control_entries("input", attrs, _children, fieldset_stack) do
    case {attribute(attrs, "name"), DisabledState.control_disabled?(attrs, fieldset_stack)} do
      {nil, _} ->
        []

      {_name, true} ->
        []

      {name, false} ->
        attrs
        |> input_value()
        |> case do
          {:include, value} -> [{name, value}]
          :ignore -> []
        end
    end
  end

  defp control_entries("textarea", attrs, children, fieldset_stack) do
    case {attribute(attrs, "name"), DisabledState.control_disabled?(attrs, fieldset_stack)} do
      {nil, _} -> []
      {_name, true} -> []
      {name, false} -> [{name, node_text("textarea", attrs, children)}]
    end
  end

  defp control_entries("select", attrs, children, fieldset_stack) do
    case {attribute(attrs, "name"), DisabledState.control_disabled?(attrs, fieldset_stack)} do
      {nil, _} ->
        []

      {_name, true} ->
        []

      {name, false} ->
        options = select_options(children)
        selected = Enum.filter(options, &(&1.selected? and not &1.disabled?))
        any_selected = Enum.any?(options, & &1.selected?)

        if has_attribute?(attrs, "multiple") do
          Enum.map(selected, &{name, &1.value})
        else
          case selected do
            [first_selected | _] ->
              [{name, first_selected.value}]

            [] ->
              # Browser behavior keeps an explicitly selected disabled option state
              # without falling back to the first enabled option.
              if any_selected do
                []
              else
                case Enum.find(options, &(!&1.disabled?)) do
                  nil -> []
                  first_option -> [{name, first_option.value}]
                end
              end
          end
        end
    end
  end

  defp control_entries(_tag, _attrs, _children, _fieldset_stack), do: []

  defp input_value(attrs) do
    type = attribute(attrs, "type")

    cond do
      type in ["checkbox", "radio"] ->
        if has_attribute?(attrs, "checked") do
          {:include, attribute(attrs, "value") || "on"}
        else
          :ignore
        end

      type == "hidden" ->
        {:include, attribute(attrs, "value") || ""}

      type in @simple_value_types ->
        {:include, attribute(attrs, "value") || ""}

      is_nil(type) ->
        {:include, attribute(attrs, "value") || ""}

      MapSet.member?(@excluded_input_types, type) ->
        :ignore

      true ->
        :ignore
    end
  end

  defp select_options(children) do
    children
    |> collect_option_nodes(false, [])
    |> Enum.reverse()
  end

  defp collect_option_nodes([], _optgroup_disabled, acc), do: acc

  defp collect_option_nodes([node | rest], optgroup_disabled, acc) do
    acc =
      case node do
        {"option", attrs, children} ->
          option = %{
            selected?: has_attribute?(attrs, "selected"),
            disabled?: optgroup_disabled or DisabledState.disabled_attribute?(attrs),
            value: attribute(attrs, "value") || node_text("option", attrs, children)
          }

          [option | acc]

        {"optgroup", attrs, children} ->
          child_optgroup_disabled = optgroup_disabled or DisabledState.disabled_attribute?(attrs)
          collect_option_nodes(children, child_optgroup_disabled, acc)

        {_tag, _attrs, children} ->
          collect_option_nodes(children, optgroup_disabled, acc)

        _other ->
          acc
      end

    collect_option_nodes(rest, optgroup_disabled, acc)
  end

  defp node_text(tag, attrs, children) do
    Html.element_text(LazyHTML.from_tree([{tag, attrs, children}]))
  end

  defp attribute(attrs, attr_name) do
    attrs
    |> Enum.find_value(fn
      {^attr_name, value} -> value
      _ -> nil
    end)
    |> normalize_attribute(attr_name)
  end

  defp normalize_attribute(nil, _attr_name), do: nil
  defp normalize_attribute(value, "type"), do: String.downcase(value)
  defp normalize_attribute(value, _attr_name), do: value

  defp has_attribute?(attrs, attr_name) do
    Enum.any?(attrs, fn
      {^attr_name, _value} -> true
      _ -> false
    end)
  end
end
