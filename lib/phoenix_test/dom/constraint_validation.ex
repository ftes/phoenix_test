defmodule PhoenixTest.DOM.ConstraintValidation do
  @moduledoc false

  alias PhoenixTest.FormData
  alias PhoenixTest.Html

  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @non_validated_input_types MapSet.new(~w(button hidden image reset submit))
  @pattern_input_types MapSet.new(~w(email password search tel text url))
  @length_input_types MapSet.new(~w(email password search tel text url))
  @numeric_input_types MapSet.new(~w(number range))
  @float_epsilon 1.0e-9

  def valid_for_submit?(form, form_data, submitter \\ nil)

  def valid_for_submit?(form, %FormData{} = form_data, submitter) do
    if bypass_validation?(form, submitter) do
      true
    else
      controls_valid?(form, form_data.data)
    end
  end

  def valid_for_submit?(form, form_data, submitter) when is_map(form_data) do
    valid_for_submit?(form, %FormData{data: form_data}, submitter)
  end

  defp bypass_validation?(form, submitter) do
    boolean_attr?(form.parsed, "novalidate") || submitter_boolean_attr?(submitter, "formnovalidate")
  end

  defp submitter_boolean_attr?(%{parsed: parsed}, attr), do: boolean_attr?(parsed, attr)
  defp submitter_boolean_attr?(_, _attr), do: false

  defp controls_valid?(form, data_map) do
    form.parsed
    |> Html.all("input,textarea,select")
    |> Enum.all?(&control_valid?(&1, data_map))
  end

  defp control_valid?(control, data_map) do
    if boolean_attr?(control, "disabled") do
      true
    else
      required_valid?(control, data_map) and
        type_valid?(control, data_map) and
        pattern_valid?(control, data_map) and
        length_valid?(control, data_map) and
        numeric_range_valid?(control, data_map) and
        step_valid?(control, data_map)
    end
  end

  defp required_valid?(control, data_map) do
    if has_required?(control) do
      case {element_tag(control), input_type(control)} do
        {"input", type} when type in ["checkbox", "radio"] ->
          required_choice_present?(control, data_map)

        {"input", type} ->
          if MapSet.member?(@non_validated_input_types, type) do
            true
          else
            required_value_present?(control, data_map)
          end

        {_tag, _type} ->
          required_value_present?(control, data_map)
      end
    else
      true
    end
  end

  defp required_choice_present?(control, data_map) do
    case Html.attribute(control, "name") do
      nil -> boolean_attr?(control, "checked")
      name -> present_value?(Map.get(data_map, name))
    end
  end

  defp required_value_present?(control, data_map) do
    present_value?(control_value(control, data_map))
  end

  defp type_valid?(control, data_map) do
    case {element_tag(control), input_type(control), Html.attribute(control, "name")} do
      {"input", "email", name} when is_binary(name) ->
        validate_email(control_value(control, data_map), boolean_attr?(control, "multiple"))

      _ ->
        true
    end
  end

  defp pattern_valid?(control, data_map) do
    case {element_tag(control), input_type(control), Html.attribute(control, "pattern")} do
      {"input", type, pattern} when is_binary(pattern) ->
        if MapSet.member?(@pattern_input_types, type) do
          validate_pattern(control_value(control, data_map), pattern)
        else
          true
        end

      _ ->
        true
    end
  end

  defp validate_pattern(value, _pattern) when value in [nil, ""], do: true

  defp validate_pattern(value, pattern) when is_binary(value) do
    case Regex.compile("^(?:#{pattern})$") do
      {:ok, regex} -> Regex.match?(regex, value)
      {:error, _} -> true
    end
  end

  defp validate_pattern(_value, _pattern), do: false

  defp length_valid?(control, data_map) do
    min = parse_int(Html.attribute(control, "minlength"))
    max = parse_int(Html.attribute(control, "maxlength"))

    case {element_tag(control), input_type(control), min, max} do
      {_tag, _type, nil, nil} ->
        true

      {"textarea", _type, _min, _max} ->
        validate_length(control_value(control, data_map), min, max)

      {"input", type, _min, _max} ->
        if MapSet.member?(@length_input_types, type) do
          validate_length(control_value(control, data_map), min, max)
        else
          true
        end

      _ ->
        true
    end
  end

  defp validate_length(value, _min, _max) when value in [nil, ""], do: true

  defp validate_length(value, min, max) when is_binary(value) do
    length = String.length(value)
    min_ok?(length, min) and max_ok?(length, max)
  end

  defp validate_length(_value, _min, _max), do: false

  defp numeric_range_valid?(control, data_map) do
    case {element_tag(control), input_type(control)} do
      {"input", type} ->
        if MapSet.member?(@numeric_input_types, type) do
          validate_numeric_range(
            control_value(control, data_map),
            Html.attribute(control, "min"),
            Html.attribute(control, "max")
          )
        else
          true
        end

      _ ->
        true
    end
  end

  defp validate_numeric_range(value, _min, _max) when value in [nil, ""], do: true

  defp validate_numeric_range(value, min, max) when is_binary(value) do
    case parse_float(value) do
      {:ok, number} -> min_ok?(number, parse_float_or_nil(min)) and max_ok?(number, parse_float_or_nil(max))
      :error -> false
    end
  end

  defp validate_numeric_range(_value, _min, _max), do: false

  defp step_valid?(control, data_map) do
    case {element_tag(control), input_type(control), Html.attribute(control, "step")} do
      {"input", type, step} when is_binary(step) ->
        if MapSet.member?(@numeric_input_types, type) do
          validate_step(control_value(control, data_map), Html.attribute(control, "min"), step)
        else
          true
        end

      _ ->
        true
    end
  end

  defp validate_step(_value, _min, "any"), do: true
  defp validate_step(value, _min, _step) when value in [nil, ""], do: true

  defp validate_step(value, min, step) when is_binary(value) do
    case parse_float(value) do
      :error ->
        false

      {:ok, number} ->
        case parse_float(step) do
          :error ->
            true

          {:ok, step_value} when step_value > 0 ->
            base = parse_float_or_nil(min) || 0.0
            ratio = (number - base) / step_value
            close_to_integer?(ratio)

          {:ok, _step_value} ->
            true
        end
    end
  end

  defp validate_step(_value, _min, _step), do: false

  defp validate_email(value, multiple?)

  defp validate_email(value, _multiple?) when value in [nil, ""], do: true

  defp validate_email(value, true) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.all?(&valid_email?/1)
  end

  defp validate_email(value, _multiple?) when is_binary(value), do: valid_email?(value)
  defp validate_email(_value, _multiple?), do: false

  defp valid_email?(email) do
    Regex.match?(@email_regex, email)
  end

  defp control_value(control, data_map) do
    name = Html.attribute(control, "name")
    current_value(control, Map.get(data_map, name))
  end

  defp current_value(control, nil) do
    case element_tag(control) do
      "textarea" -> Html.element_text(control)
      _ -> Html.attribute(control, "value") || ""
    end
  end

  defp current_value(_control, value), do: value

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> nil
    end
  end

  defp parse_int(_), do: nil

  defp parse_float_or_nil(nil), do: nil

  defp parse_float_or_nil(value) when is_binary(value) do
    case parse_float(value) do
      {:ok, number} -> number
      :error -> nil
    end
  end

  defp parse_float_or_nil(_), do: nil

  defp parse_float(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> {:ok, number}
      _ -> :error
    end
  end

  defp parse_float(_), do: :error

  defp min_ok?(_value, nil), do: true
  defp min_ok?(value, min), do: value >= min

  defp max_ok?(_value, nil), do: true
  defp max_ok?(value, max), do: value <= max

  defp close_to_integer?(number) do
    rounded = Float.round(number)
    abs(number - rounded) <= @float_epsilon
  end

  defp present_value?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_value?(value) when is_list(value), do: Enum.any?(value, &present_value?/1)
  defp present_value?(nil), do: false
  defp present_value?(_), do: true

  defp has_required?(control), do: boolean_attr?(control, "required")

  defp boolean_attr?(control, attribute) do
    not is_nil(Html.attribute(control, attribute))
  end

  defp element_tag(control) do
    case Html.element(control) do
      {tag, _attrs, _children} -> tag
      _ -> nil
    end
  end

  defp input_type(control) do
    control
    |> Html.attribute("type")
    |> case do
      nil -> "text"
      type -> String.downcase(type)
    end
  end
end
