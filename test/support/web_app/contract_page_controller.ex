defmodule PhoenixTest.WebApp.ContractPageController do
  use Phoenix.Controller, formats: [html: "View"]

  alias PhoenixTest.DomOracle.ContractCatalog

  def show(conn, %{"contract" => contract}) do
    case contract_html(contract) do
      nil -> send_resp(conn, 404, "Unknown contract fixture")
      html_content -> html(conn, html_content)
    end
  end

  def contract_html(contract), do: ContractCatalog.contract_html(contract)
end
