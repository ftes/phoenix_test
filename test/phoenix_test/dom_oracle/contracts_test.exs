defmodule PhoenixTest.DomOracle.ContractsTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import PhoenixTest

  alias PhoenixTest.Driver
  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData
  alias PhoenixTest.OracleDiff
  alias PhoenixTest.OracleNormalize
  alias PhoenixTest.OracleRunner

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
      expected: :mismatch,
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
      expected: :mismatch
    },
    %{
      id: "C018",
      name: "constraint validation blocks invalid submit",
      path: "/page/contracts/c018",
      steps: [%{"op" => "click_button", "text" => "Save", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :mismatch
    }
  ]

  setup do
    case OracleRunner.availability() do
      :ok -> %{conn: build_conn()}
      {:error, reason} -> {:skip, "Oracle runner unavailable: #{inspect(reason)}"}
    end
  end

  for contract <- @contracts do
    @contract contract
    test "#{contract.id} #{contract.name} baseline", %{conn: conn} do
      oracle = oracle_outcome(@contract)
      ours = ours_outcome(conn, @contract)
      diff = OracleDiff.diff(oracle, ours)
      assert_expected_state(@contract, diff, oracle)
    end
  end

  defp assert_expected_state(contract, diff, oracle) do
    case {contract.expected, diff} do
      {:mismatch, {:mismatch, _message}} ->
        assert true

      {:mismatch, :ok} ->
        flunk("""
        #{contract.id} currently matches oracle output.
        Update expected to :match and continue refactor.
        payload=#{inspect(oracle, pretty: true, limit: :infinity)}
        """)

      {:match, :ok} ->
        assert true

      {:match, {:mismatch, message}} ->
        flunk("""
        #{contract.id} expected to match oracle but diverged:
        #{message}
        """)
    end
  end

  defp oracle_outcome(contract) do
    spec = %{
      "base_url" => OracleRunner.base_url(),
      "initial_path" => contract.path,
      "steps" => contract.steps,
      "capture" => contract.capture,
      "timeout_ms" => Map.get(contract, :timeout_ms, oracle_timeout_ms())
    }

    case OracleRunner.run(spec) do
      {:ok, %{"capture" => capture}} ->
        %{
          "status" => "ok",
          "payload" => normalize_capture(contract.capture, capture)
        }

      {:error, {:runner_failed, _status, payload}} ->
        %{
          "status" => "error",
          "payload" =>
            payload
            |> Map.take(["failed_step_index", "failed_op"])
            |> Map.put("message", "playwright_step_failed")
        }

      {:error, reason} ->
        raise "Oracle runner error for #{contract.id}: #{inspect(reason)}"
    end
  end

  defp ours_outcome(conn, contract) do
    session =
      conn
      |> visit(contract.path)
      |> execute_steps(contract.steps)

    payload =
      case contract.capture do
        %{"type" => "form_snapshot", "form_selector" => form_selector} ->
          ours_form_snapshot(session, form_selector)

        %{"type" => "submit_result"} ->
          ours_submit_result(session)
      end

    %{"status" => "ok", "payload" => payload}
  rescue
    exception ->
      %{
        "status" => "error",
        "payload" => %{
          "message" => Exception.message(exception),
          "type" => exception.__struct__ |> Module.split() |> List.last()
        }
      }
  end

  defp normalize_capture(%{"type" => "form_snapshot"}, capture) do
    %{"entries" => normalized_entries(capture["entries"])}
  end

  defp normalize_capture(%{"type" => "submit_result"}, capture) do
    %{
      "submitted" => capture["submitted"] == true,
      "effective_method" => capture["effective_method"],
      "effective_action" => capture["effective_action"],
      "entries" => normalized_entries(capture["entries"] || [])
    }
  end

  defp ours_form_snapshot(session, form_selector) do
    html = Driver.render_html(session)
    form = Form.find!(html, form_selector)
    merged = FormData.merge(form.form_data, session.active_form.form_data)

    %{
      "entries" =>
        merged
        |> FormData.to_list()
        |> normalized_entries()
    }
  end

  defp ours_submit_result(session) do
    params = submitted_params(session.conn)
    submitted = is_map(params)
    effective_method = if submitted, do: String.downcase(session.conn.method)
    effective_action = if submitted, do: session.conn.request_path

    %{
      "submitted" => submitted,
      "effective_method" => effective_method,
      "effective_action" => effective_action,
      "entries" => if(submitted, do: params_to_entries(params), else: [])
    }
  end

  defp submitted_params(conn) do
    cond do
      is_map(conn.assigns[:params]) ->
        conn.assigns[:params]

      is_map(conn.query_params) and map_size(conn.query_params) > 0 ->
        conn.query_params

      true ->
        nil
    end
  end

  defp execute_steps(session, []), do: session

  defp execute_steps(session, [%{"op" => "within", "mode" => "push", "selector" => selector} | rest]) do
    {inner, after_inner} = split_within_block(rest, 1, [])
    session = within(session, selector, &execute_steps(&1, inner))
    execute_steps(session, after_inner)
  end

  defp execute_steps(_session, [%{"op" => "within", "mode" => "pop"} | _]) do
    raise "Encountered unexpected within/pop while executing steps"
  end

  defp execute_steps(session, [step | rest]) do
    session
    |> execute_step(step)
    |> execute_steps(rest)
  end

  defp execute_step(session, %{"op" => "fill_in", "label" => label, "value" => value} = step) do
    opts = [with: value, exact: Map.get(step, "exact", true)]

    case Map.get(step, "selector") do
      nil -> fill_in(session, label, opts)
      selector -> fill_in(session, selector, label, opts)
    end
  end

  defp execute_step(session, %{"op" => op, "label" => label} = step) when op in ["check", "uncheck", "choose"] do
    opts = [exact: Map.get(step, "exact", true)]

    case {op, Map.get(step, "selector")} do
      {"check", nil} -> check(session, label, opts)
      {"check", selector} -> check(session, selector, label, opts)
      {"uncheck", nil} -> uncheck(session, label, opts)
      {"uncheck", selector} -> uncheck(session, selector, label, opts)
      {"choose", nil} -> choose(session, label, opts)
      {"choose", selector} -> choose(session, selector, label, opts)
    end
  end

  defp execute_step(session, %{"op" => "select", "from" => from, "option" => option} = step) do
    opts = [
      option: option,
      exact: Map.get(step, "exact", true),
      exact_option: Map.get(step, "exact_option", true)
    ]

    case Map.get(step, "selector") do
      nil -> select(session, from, opts)
      selector -> select(session, selector, from, opts)
    end
  end

  defp execute_step(session, %{"op" => "click_button", "text" => text} = step) do
    case Map.get(step, "selector") do
      nil -> click_button(session, text)
      selector -> click_button(session, selector, text)
    end
  end

  defp execute_step(session, %{"op" => "submit"}) do
    submit(session)
  end

  defp execute_step(_session, step) do
    raise "Unsupported step for PhoenixTest execution: #{inspect(step)}"
  end

  defp split_within_block([], _depth, _acc) do
    raise "Missing within/pop while executing step block"
  end

  defp split_within_block([%{"op" => "within", "mode" => "push"} = step | rest], depth, acc) do
    split_within_block(rest, depth + 1, [step | acc])
  end

  defp split_within_block([%{"op" => "within", "mode" => "pop"} | rest], 1, acc) do
    {Enum.reverse(acc), rest}
  end

  defp split_within_block([%{"op" => "within", "mode" => "pop"} = step | rest], depth, acc) do
    split_within_block(rest, depth - 1, [step | acc])
  end

  defp split_within_block([step | rest], depth, acc) do
    split_within_block(rest, depth, [step | acc])
  end

  defp params_to_entries(params) when is_map(params) do
    params
    |> flatten_param_entries()
    |> normalized_entries()
  end

  defp flatten_param_entries(params, prefix \\ nil) do
    params
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.flat_map(fn {key, value} ->
      full_key = if prefix, do: "#{prefix}[#{key}]", else: key
      flatten_value_entries(full_key, value)
    end)
  end

  defp flatten_value_entries(key, value) when is_map(value), do: flatten_param_entries(value, key)
  defp flatten_value_entries(key, value) when is_list(value), do: Enum.map(value, &[key, normalize_value(&1)])
  defp flatten_value_entries(key, value), do: [[key, normalize_value(value)]]

  defp normalized_entries(entries) do
    entries
    |> OracleNormalize.normalize_entries()
    |> Enum.map(fn {name, value} -> [name, normalize_value(value)] end)
    |> Enum.sort()
  end

  defp normalize_value(value) when is_binary(value), do: value
  defp normalize_value(value) when is_boolean(value), do: to_string(value)
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: to_string(value)

  defp oracle_timeout_ms do
    case Integer.parse(System.get_env("PHOENIX_TEST_ORACLE_TIMEOUT_MS", "7000")) do
      {ms, ""} when ms > 0 -> ms
      _ -> 7_000
    end
  end
end
