defmodule PhoenixTest.OracleNormalize do
  @moduledoc false

  def normalize(value) when is_map(value) do
    value
    |> Enum.map(fn {key, item} -> {normalize_key(key), normalize(item)} end)
    |> Enum.sort_by(fn {key, _item} -> key end)
    |> Map.new()
  end

  def normalize(value) when is_list(value), do: Enum.map(value, &normalize/1)
  def normalize(value) when is_tuple(value), do: value |> Tuple.to_list() |> normalize()
  def normalize(value) when is_atom(value), do: Atom.to_string(value)
  def normalize(value), do: value

  def normalize_entries(entries) when is_list(entries) do
    Enum.map(entries, fn
      [name, value] -> {to_string(name), normalize(value)}
      {name, value} -> {to_string(name), normalize(value)}
    end)
  end

  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(key), do: key
end
