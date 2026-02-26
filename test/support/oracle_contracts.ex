defmodule PhoenixTest.OracleContracts do
  @moduledoc false

  @contracts [
    %{
      id: "C001",
      name: "disabled hidden control excluded",
      path: "/page/contracts/c001",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c001-form"},
      expected: :match
    },
    %{
      id: "C002",
      name: "checked checkbox without value defaults to on",
      path: "/page/contracts/c002",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c002-form"},
      expected: :match
    },
    %{
      id: "C003",
      name: "disabled fieldset descendants excluded",
      path: "/page/contracts/c003",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c003-form"},
      expected: :match
    },
    %{
      id: "C004",
      name: "form associated input submit flow",
      path: "/page/contracts/c004",
      steps: [
        %{
          "op" => "fill_in",
          "selector" => "#c004-name",
          "label" => "External Name",
          "value" => "outside-updated",
          "exact" => true
        },
        %{"op" => "submit", "form_selector" => "#c004-form"}
      ],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C005",
      name: "form associated select submit flow",
      path: "/page/contracts/c005",
      steps: [
        %{
          "op" => "select",
          "selector" => "#c005-race",
          "from" => "Race",
          "option" => "Human",
          "exact" => true
        },
        %{"op" => "submit", "form_selector" => "#c005-form"}
      ],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C006",
      name: "type button with form is not submitter",
      path: "/page/contracts/c006",
      steps: [%{"op" => "click_button", "text" => "External Action", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C007",
      name: "default submitter supports input submit",
      path: "/page/contracts/c007",
      steps: [
        %{
          "op" => "fill_in",
          "selector" => "#c007-name",
          "label" => "Name",
          "value" => "Aragorn",
          "exact" => true
        },
        %{"op" => "submit", "form_selector" => "#c007-form"}
      ],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C008",
      name: "hidden fallback is scoped by form owner",
      path: "/page/contracts/c008",
      steps: [
        %{
          "op" => "uncheck",
          "selector" => "#c008-subscribe-a",
          "label" => "Subscribe A",
          "exact" => true
        }
      ],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c008-form-a"},
      expected: :match
    },
    %{
      id: "C009",
      name: "disabled button click blocked",
      path: "/page/contracts/c009",
      steps: [%{"op" => "click_button", "text" => "Disabled Save", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match,
      timeout_ms: 2_000
    },
    %{
      id: "C010",
      name: "radio without value defaults to on",
      path: "/page/contracts/c010",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c010-form"},
      expected: :match
    },
    %{
      id: "C011",
      name: "only actual submitter contributes name value",
      path: "/page/contracts/c011",
      steps: [%{"op" => "click_button", "text" => "Save B", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C012",
      name: "submitter formmethod and formaction override",
      path: "/page/contracts/c012",
      steps: [%{"op" => "click_button", "text" => "Save Override", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C013",
      name: "controls without name are excluded",
      path: "/page/contracts/c013",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c013-form"},
      expected: :match
    },
    %{
      id: "C014",
      name: "single select no selected defaults to first option",
      path: "/page/contracts/c014",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c014-form"},
      expected: :match
    },
    %{
      id: "C015",
      name: "multiple select without selected options yields no entries",
      path: "/page/contracts/c015",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c015-form"},
      expected: :match
    },
    %{
      id: "C016",
      name: "explicit and implicit label association parity",
      path: "/page/contracts/c016",
      steps: [
        %{"op" => "fill_in", "label" => "Explicit Name", "value" => "Aragorn", "exact" => true},
        %{"op" => "fill_in", "label" => "Implicit Name", "value" => "Legolas", "exact" => true}
      ],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c016-form"},
      expected: :match
    },
    %{
      id: "C017",
      name: "image submitter coordinates handling",
      path: "/page/contracts/c017",
      steps: [%{"op" => "click_button", "text" => "Image Save", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :ignore
    },
    %{
      id: "C018",
      name: "constraint validation blocks invalid submit",
      path: "/page/contracts/c018",
      steps: [%{"op" => "click_button", "text" => "Save", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    }
  ]

  def for_surface(:static), do: @contracts

  def for_surface(:live) do
    Enum.map(@contracts, fn contract ->
      %{contract | path: String.replace_prefix(contract.path, "/page/contracts/", "/live/contracts/")}
    end)
  end
end
