defmodule PhoenixTest.WebApp.ContractLive do
  @moduledoc false

  use Phoenix.LiveView

  alias PhoenixTest.WebApp.LiveContracts

  def mount(%{"contract" => contract}, _session, socket) do
    {:ok, assign(socket, fixture_html: LiveContracts.html(contract))}
  end

  def render(assigns) do
    ~H"""
    <%= if @fixture_html do %>
      {Phoenix.HTML.raw(@fixture_html)}
    <% else %>
      <main>
        <h1>Unknown contract fixture</h1>
      </main>
    <% end %>
    """
  end
end
