defmodule PhoenixTest.WebApp.LiveServerContractLive do
  @moduledoc false

  use Phoenix.LiveView

  def mount(%{"contract" => contract}, _session, socket) do
    {:ok,
     assign(socket,
       contract: contract,
       current_path: "",
       l001_result: "pending",
       l002_saved: "0",
       l003_result: "pending"
     )}
  end

  def handle_params(params, uri, socket) do
    {:noreply,
     socket
     |> assign(:current_path, path_from_uri(uri))
     |> assign(:l002_saved, Map.get(params, "saved", "0"))}
  end

  def handle_event("save_l001", params, socket) do
    name = Map.get(params, "name", "")
    newsletter = Map.get(params, "newsletter", "nil")
    result = "name=#{name};newsletter=#{newsletter}"

    {:noreply, assign(socket, :l001_result, result)}
  end

  def handle_event("save_l002", _params, socket) do
    {:noreply, push_patch(socket, to: "/live/server_contracts/l002?saved=1")}
  end

  def handle_event("save_l003", params, socket) do
    profile = Map.get(params, "profile", %{})
    roles = params |> Map.get("roles", []) |> List.wrap() |> Enum.join(",")

    result =
      "profile.name=#{Map.get(profile, "name", "")};profile.race=#{Map.get(profile, "race", "")};roles=#{roles}"

    {:noreply, assign(socket, :l003_result, result)}
  end

  def render(assigns) do
    ~H"""
    <%= case @contract do %>
      <% "l001" -> %>
        <main data-contract="l001">
          <h1>L001</h1>

          <form id="l001-form" phx-submit="save_l001">
            <label for="l001-name">Name</label>
            <input id="l001-name" type="text" name="name" value="Frodo" />

            <label for="l001-newsletter">Newsletter</label>
            <input id="l001-newsletter" type="checkbox" name="newsletter" value="yes" />

            <button type="submit">Save</button>
          </form>

          <pre id="l001-result">{@l001_result}</pre>
        </main>
      <% "l002" -> %>
        <main data-contract="l002">
          <h1>L002</h1>

          <form id="l002-form" phx-submit="save_l002">
            <button type="submit">Save</button>
          </form>

          <pre id="l002-saved">{@l002_saved}</pre>
          <pre id="l002-path">{@current_path}</pre>
        </main>
      <% "l003" -> %>
        <main data-contract="l003">
          <h1>L003</h1>

          <form id="l003-form" phx-submit="save_l003">
            <label for="l003-name">Profile Name</label>
            <input id="l003-name" type="text" name="profile[name]" value="Bilbo" />

            <label for="l003-race">Race</label>
            <select id="l003-race" name="profile[race]">
              <option value="human">Human</option>
              <option value="hobbit" selected>Hobbit</option>
            </select>

            <label for="l003-role-admin">Role Admin</label>
            <input id="l003-role-admin" type="checkbox" name="roles[]" value="admin" checked />

            <label for="l003-role-editor">Role Editor</label>
            <input id="l003-role-editor" type="checkbox" name="roles[]" value="editor" />

            <button type="submit">Save</button>
          </form>

          <pre id="l003-result">{@l003_result}</pre>
        </main>
      <% _ -> %>
        <main>
          <h1>Unknown live server contract fixture</h1>
        </main>
    <% end %>
    """
  end

  defp path_from_uri(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{path: path, query: nil} when is_binary(path) -> path
      %URI{path: path, query: query} when is_binary(path) -> path <> "?" <> query
      _ -> ""
    end
  end
end
