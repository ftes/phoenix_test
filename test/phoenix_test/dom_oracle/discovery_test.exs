defmodule PhoenixTest.DomOracle.DiscoveryTest do
  use ExUnit.Case, async: false

  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData
  alias PhoenixTest.OracleDiff
  alias PhoenixTest.OracleNormalize
  alias PhoenixTest.OracleRunner

  @form_selector "#discovery-form"

  setup do
    case OracleRunner.availability() do
      :ok -> :ok
      {:error, reason} -> {:skip, "Oracle runner unavailable: #{inspect(reason)}"}
    end
  end

  test "generated form-serialization matrix matches browser oracle" do
    mismatches =
      Enum.flat_map(discovery_cases(), fn test_case ->
        oracle = oracle_entries(test_case.html)
        ours = ours_entries(test_case.html)

        case OracleDiff.diff(%{"entries" => oracle}, %{"entries" => ours}) do
          :ok -> []
          {:mismatch, message} -> [%{id: test_case.id, description: test_case.description, message: message}]
        end
      end)

    assert mismatches == [],
           """
           Discovery matrix found unexpected oracle mismatches:

           #{Enum.map_join(mismatches, "\n\n", &format_mismatch/1)}
           """
  end

  defp discovery_cases do
    checkbox_cases() ++
      radio_cases() ++
      text_cases() ++
      [hidden_case(), unnamed_case(), fieldset_case()] ++
      select_cases() ++
      multi_select_cases()
  end

  defp checkbox_cases do
    for checked <- [false, true],
        value <- [nil, "yes"],
        disabled <- [false, true] do
      attrs =
        attrs_to_string([
          {"type", "checkbox"},
          {"name", "flag"},
          {"value", value},
          {"checked", checked},
          {"disabled", disabled}
        ])

      %{
        id: "checkbox_checked_#{checked}_value_#{value || "nil"}_disabled_#{disabled}",
        description: "checkbox combinations",
        html: wrap_form("<input #{attrs} />")
      }
    end
  end

  defp radio_cases do
    for checked <- [false, true],
        value <- [nil, "mail"],
        disabled <- [false, true] do
      attrs =
        attrs_to_string([
          {"type", "radio"},
          {"name", "contact"},
          {"value", value},
          {"checked", checked},
          {"disabled", disabled}
        ])

      %{
        id: "radio_checked_#{checked}_value_#{value || "nil"}_disabled_#{disabled}",
        description: "radio combinations",
        html: wrap_form("<input #{attrs} />")
      }
    end
  end

  defp text_cases do
    for value <- [nil, "Aragorn"],
        disabled <- [false, true],
        type <- ["text", nil] do
      attrs =
        attrs_to_string([{"type", type}, {"name", "name"}, {"value", value}, {"disabled", disabled}])

      %{
        id: "text_type_#{type || "default"}_value_#{value || "nil"}_disabled_#{disabled}",
        description: "text-input combinations",
        html: wrap_form("<input #{attrs} />")
      }
    end
  end

  defp hidden_case do
    %{
      id: "hidden_disabled_toggle",
      description: "hidden enabled + disabled control pair",
      html:
        wrap_form("""
        <input type="hidden" name="token_enabled" value="abc" />
        <input type="hidden" name="token_disabled" value="xyz" disabled />
        """)
    }
  end

  defp unnamed_case do
    %{
      id: "unnamed_controls_excluded",
      description: "controls without name are excluded",
      html:
        wrap_form("""
        <input type="text" value="value" />
        <textarea>hello</textarea>
        <select><option selected value="v">V</option></select>
        """)
    }
  end

  defp fieldset_case do
    %{
      id: "fieldset_disabled_first_legend_exception",
      description: "fieldset disabled descendants except first legend",
      html:
        wrap_form("""
        <fieldset disabled>
          <legend>
            Name
            <input type="text" name="legend_allowed" value="yes" />
          </legend>
          <input type="text" name="blocked" value="no" />
        </fieldset>
        """)
    }
  end

  defp select_cases do
    [
      %{
        id: "select_selected_option",
        description: "single select uses selected option",
        html:
          wrap_form("""
          <select name="race">
            <option value="human">Human</option>
            <option value="elf" selected>Elf</option>
          </select>
          """)
      },
      %{
        id: "select_first_option_default",
        description: "single select defaults to first option when none selected",
        html:
          wrap_form("""
          <select name="race">
            <option value="human">Human</option>
            <option value="elf">Elf</option>
          </select>
          """)
      },
      %{
        id: "select_first_enabled_option_default",
        description: "single select skips disabled options for default selection",
        html:
          wrap_form("""
          <select name="race">
            <option value="human" disabled>Human</option>
            <option value="elf">Elf</option>
          </select>
          """)
      }
    ]
  end

  defp multi_select_cases do
    [
      %{
        id: "multi_select_selected_options",
        description: "multi-select keeps selected options in order",
        html:
          wrap_form("""
          <select name="races[]" multiple>
            <option value="human" selected>Human</option>
            <option value="elf" selected>Elf</option>
            <option value="dwarf">Dwarf</option>
          </select>
          """)
      },
      %{
        id: "multi_select_no_selected_options",
        description: "multi-select with no selected options contributes nothing",
        html:
          wrap_form("""
          <select name="races[]" multiple>
            <option value="human">Human</option>
            <option value="elf">Elf</option>
          </select>
          """)
      },
      %{
        id: "multi_select_disabled_selected_option",
        description: "disabled selected option is excluded",
        html:
          wrap_form("""
          <select name="races[]" multiple>
            <option value="human" selected disabled>Human</option>
            <option value="elf" selected>Elf</option>
          </select>
          """)
      }
    ]
  end

  defp wrap_form(inner) do
    """
    <main>
      <form id="discovery-form">
        #{inner}
      </form>
    </main>
    """
  end

  defp oracle_entries(html) do
    spec = %{
      "base_url" => OracleRunner.base_url(),
      "initial_path" => to_data_url(html),
      "steps" => [],
      "capture" => %{"type" => "form_snapshot", "form_selector" => @form_selector},
      "timeout_ms" => 2_000
    }

    case OracleRunner.run(spec) do
      {:ok, %{"capture" => %{"entries" => entries}}} ->
        OracleNormalize.normalize_entries(entries)

      {:error, reason} ->
        raise "Oracle runner error for discovery case: #{inspect(reason)}"
    end
  end

  defp ours_entries(html) do
    html
    |> Form.find!(@form_selector)
    |> Map.fetch!(:form_data)
    |> FormData.to_list()
    |> OracleNormalize.normalize_entries()
  end

  defp format_mismatch(mismatch) do
    """
    #{mismatch.id}: #{mismatch.description}
    #{mismatch.message}
    """
  end

  defp to_data_url(html) do
    "data:text/html;base64," <> Base.encode64(html)
  end

  defp attrs_to_string(attrs) do
    attrs
    |> Enum.flat_map(fn
      {_key, nil} -> []
      {key, true} -> [key]
      {_key, false} -> []
      {key, value} -> [~s(#{key}="#{value}")]
    end)
    |> Enum.join(" ")
  end
end
