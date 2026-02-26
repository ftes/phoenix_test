defmodule PhoenixTest.WebApp.LiveContracts do
  @moduledoc false

  alias PhoenixTest.DomOracle.ContractCatalog

  def html(contract), do: ContractCatalog.contract_html(contract)
end
