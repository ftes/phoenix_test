defmodule PhoenixTest.FormData do
  @moduledoc false

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Select

  defstruct data: %{}, entries: []

  def new(opts \\ []) when is_list(opts) do
    struct!(__MODULE__, Keyword.merge([data: %{}, entries: []], opts))
  end

  def from_entries(entries) when is_list(entries) do
    normalized_entries =
      Enum.map(entries, fn {name, value} -> {to_string(name), value} end)

    %__MODULE__{
      entries: normalized_entries,
      data: data_from_entries(normalized_entries)
    }
  end

  def add_data(%__MODULE__{} = form_data, {name, value}) do
    add_data(form_data, name, value)
  end

  def add_data(%__MODULE__{} = form_data, %Button{} = button) do
    add_data(form_data, button.name, button.value)
  end

  def add_data(%__MODULE__{} = form_data, %Field{} = field) do
    add_data(form_data, field.name, field.value)
  end

  def add_data(%__MODULE__{} = form_data, %Select{value: values} = field) when is_list(values) do
    add_data(form_data, field.name, values)
  end

  def add_data(form_data, data) when is_list(data) do
    Enum.reduce(data, form_data, fn new_data, acc ->
      add_data(acc, new_data)
    end)
  end

  def add_data(%__MODULE__{} = form_data, name, value) when is_binary(name) and is_list(value) do
    if allows_multiple_values?(name) do
      Enum.reduce(value, form_data, fn item, acc ->
        add_single_entry(acc, name, item)
      end)
    else
      entries =
        form_data.entries
        |> Enum.reject(fn {existing_name, _existing_value} -> existing_name == name end)
        |> Kernel.++(Enum.map(value, &{name, &1}))

      %__MODULE__{form_data | entries: entries, data: data_from_entries(entries)}
    end
  end

  def add_data(%__MODULE__{} = form_data, name, value) when is_nil(name) or is_nil(value), do: form_data

  def add_data(%__MODULE__{} = form_data, name, value) do
    name = to_string(name)

    add_single_entry(form_data, name, value)
  end

  def merge(%__MODULE__{} = left, %__MODULE__{} = right) do
    right.entries
    |> Enum.group_by(fn {name, _value} -> name end, fn {_name, value} -> value end)
    |> Enum.reduce(left, fn {name, values}, acc ->
      merge_name_values(acc, name, values)
    end)
  end

  defp allows_multiple_values?(field_name), do: String.ends_with?(field_name, "[]")

  def filter(%__MODULE__{entries: entries}, fun) do
    filtered_entries =
      Enum.filter(entries, fn {name, value} ->
        fun.(%{name: name, value: value})
      end)

    from_entries(filtered_entries)
  end

  def empty?(%__MODULE__{entries: entries}) do
    Enum.empty?(entries)
  end

  def has_data?(%__MODULE__{entries: entries}, name, value) do
    Enum.any?(entries, fn {entry_name, entry_value} ->
      entry_name == name and entry_value == value
    end)
  end

  def to_list(%__MODULE__{entries: entries}) do
    entries
  end

  defp add_single_entry(%__MODULE__{entries: entries} = form_data, name, value) do
    entries =
      if allows_multiple_values?(name) do
        if {name, value} in entries, do: entries, else: entries ++ [{name, value}]
      else
        entries
        |> Enum.reject(fn {existing_name, _existing_value} -> existing_name == name end)
        |> Kernel.++([{name, value}])
      end

    %__MODULE__{form_data | entries: entries, data: data_from_entries(entries)}
  end

  defp merge_name_values(%__MODULE__{entries: entries} = form_data, name, values) do
    entries =
      if allows_multiple_values?(name) do
        Enum.reduce(values, entries, fn value, acc ->
          if {name, value} in acc, do: acc, else: acc ++ [{name, value}]
        end)
      else
        entries
        |> Enum.reject(fn {existing_name, _existing_value} -> existing_name == name end)
        |> Kernel.++(Enum.map(values, &{name, &1}))
      end

    %__MODULE__{form_data | entries: entries, data: data_from_entries(entries)}
  end

  defp data_from_entries(entries) do
    Enum.reduce(entries, %{}, fn {name, value}, acc ->
      if allows_multiple_values?(name) do
        Map.update(acc, name, [value], fn existing_values ->
          if value in existing_values do
            existing_values
          else
            existing_values ++ [value]
          end
        end)
      else
        Map.put(acc, name, value)
      end
    end)
  end
end
