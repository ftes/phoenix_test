defmodule PhoenixTest.Element do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def build_selector(%LazyHTML{} = html) do
    {tag, attributes, _} = Html.element(html)

    Enum.reduce_while(attributes, tag, fn
      {"id", id}, _ when is_binary(id) ->
        {:halt, "[id=#{inspect(id)}]"}

      {"phx-" <> _rest = phx_attr, value}, acc ->
        if encoded_live_view_js?(value) do
          {:cont, acc}
        else
          {:cont, acc <> "[#{phx_attr}=#{inspect(value)}]"}
        end

      {"class", _}, acc ->
        {:cont, acc}

      {k, v}, acc ->
        {:cont, acc <> "[#{k}=#{inspect(v)}]"}
    end)
  end

  defp encoded_live_view_js?(value) do
    value =~ "[["
  end

  def selector_has_id?(selector, id) when is_binary(selector) and is_binary(id) do
    Enum.any?(["[id='#{id}'", ~s|[id="#{id}"|, "##{id}"], &String.contains?(selector, &1))
  end

  def has_ancestor?(html, ancestor_selector, descendant) do
    case Query.find_ancestor(html, ancestor_selector, descendant_selector(descendant)) do
      {:found, _} -> true
      _ -> false
    end
  end

  def descendant_selector(selector) when is_binary(selector), do: selector
  def descendant_selector({selector, text}) when is_binary(selector) and is_binary(text), do: {selector, text}
  def descendant_selector(%{id: id}) when is_binary(id), do: "[id=#{inspect(id)}]"
  def descendant_selector(%{selector: selector, text: text}), do: {selector, text}
  def descendant_selector(%{selector: selector}), do: selector
end
