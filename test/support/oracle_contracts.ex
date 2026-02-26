defmodule PhoenixTest.OracleContracts do
  @moduledoc false

  alias PhoenixTest.DomOracle.ContractCatalog

  def for_surface(:static), do: ContractCatalog.contracts()

  def for_surface(:live) do
    Enum.map(ContractCatalog.contracts(), fn contract ->
      %{contract | path: String.replace_prefix(contract.path, "/page/contracts/", "/live/contracts/")}
    end)
  end
end
