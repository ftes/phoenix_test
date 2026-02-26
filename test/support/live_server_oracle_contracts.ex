defmodule PhoenixTest.LiveServerOracleContracts do
  @moduledoc false

  @contracts [
    %{
      id: "L001",
      name: "phx-submit sends checkbox and text payload to live handler",
      path: "/live/server_contracts/l001",
      steps: [
        %{"op" => "fill_in", "label" => "Name", "value" => "Aragorn", "exact" => true},
        %{"op" => "check", "label" => "Newsletter", "exact" => true},
        %{"op" => "click_button", "text" => "Save", "exact" => true}
      ],
      capture: %{
        "type" => "selector_text",
        "selector" => "#l001-result",
        "wait_for_text" => "name=Aragorn;newsletter=yes"
      },
      expected: :match
    },
    %{
      id: "L002",
      name: "phx-submit can push_patch and update current path",
      path: "/live/server_contracts/l002",
      steps: [
        %{"op" => "click_button", "text" => "Save", "exact" => true}
      ],
      capture: %{
        "type" => "current_path",
        "wait_for_contains" => "?saved=1"
      },
      expected: :match
    },
    %{
      id: "L003",
      name: "phx-submit parses nested params and arrays",
      path: "/live/server_contracts/l003",
      steps: [
        %{"op" => "fill_in", "label" => "Profile Name", "value" => "Samwise", "exact" => true},
        %{"op" => "select", "from" => "Race", "option" => "Human", "exact" => true},
        %{"op" => "check", "label" => "Role Editor", "exact" => true},
        %{"op" => "click_button", "text" => "Save", "exact" => true}
      ],
      capture: %{
        "type" => "selector_text",
        "selector" => "#l003-result",
        "wait_for_text" => "profile.name=Samwise;profile.race=human;roles=admin,editor"
      },
      expected: :match
    }
  ]

  def contracts, do: @contracts
end
