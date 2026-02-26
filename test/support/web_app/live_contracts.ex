defmodule PhoenixTest.WebApp.LiveContracts do
  @moduledoc false

  alias PhoenixTest.WebApp.ContractPageController

  def html(contract), do: ContractPageController.contract_html(contract)
end
