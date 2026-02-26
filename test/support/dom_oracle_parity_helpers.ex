defmodule PhoenixTest.DomOracle.ParityHelpers do
  @moduledoc false

  alias PhoenixTest.Driver
  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData
  alias PhoenixTest.OracleContracts
  alias PhoenixTest.OracleNormalize
  alias PhoenixTest.OracleRunner

  defmodule StepExecutionError do
    @moduledoc false
    defexception [:failed_step_index, :failed_op, message: "playwright_step_failed"]
  end

  def parity_cases do
    Enum.flat_map([:static, :live], fn surface ->
      Enum.map(OracleContracts.for_surface(surface), &Map.put(&1, :surface, surface))
    end)
  end

  def assert_expected_state(contract, diff, oracle) do
    label = contract_label(contract)

    case {contract.expected, diff} do
      {:ignore, _} ->
        :ok

      {:mismatch, {:mismatch, _message}} ->
        :ok

      {:mismatch, :ok} ->
        raise ExUnit.AssertionError, """
        #{label} currently matches oracle output.
        Update expected to :match and continue refactor.
        payload=#{inspect(oracle, pretty: true, limit: :infinity)}
        """

      {:match, :ok} ->
        :ok

      {:match, {:mismatch, message}} ->
        raise ExUnit.AssertionError, """
        #{label} expected to match oracle but diverged:
        #{message}
        """
    end
  end

  def oracle_outcome(contract) do
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
        raise "Oracle runner error for #{contract_label(contract)}: #{inspect(reason)}"
    end
  end

  def ours_outcome(conn, contract) do
    session =
      conn
      |> PhoenixTest.visit(contract.path)
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
    exception in StepExecutionError ->
      %{
        "status" => "error",
        "payload" => %{
          "failed_step_index" => exception.failed_step_index,
          "failed_op" => exception.failed_op,
          "message" => "playwright_step_failed"
        }
      }

    exception ->
      %{
        "status" => "error",
        "payload" => %{
          "message" => Exception.message(exception),
          "type" => exception.__struct__ |> Module.split() |> List.last()
        }
      }
  end

  defp contract_label(contract) do
    "#{contract.surface} #{contract.id} #{contract.name}"
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

  defp execute_steps(session, steps), do: execute_steps(session, steps, 0)

  defp execute_steps(session, [], _step_index), do: session

  defp execute_steps(session, [%{"op" => "within", "mode" => "push", "selector" => selector} | rest], step_index) do
    {inner, after_inner} = split_within_block(rest, 1, [])
    session = PhoenixTest.within(session, selector, &execute_steps(&1, inner, step_index + 1))
    execute_steps(session, after_inner, step_index + 2 + length(inner))
  end

  defp execute_steps(_session, [%{"op" => "within", "mode" => "pop"} | _], step_index) do
    raise StepExecutionError,
      failed_step_index: step_index,
      failed_op: "within",
      message: "Encountered unexpected within/pop while executing steps"
  end

  defp execute_steps(session, [step | rest], step_index) do
    session
    |> execute_step(step, step_index)
    |> execute_steps(rest, step_index + 1)
  end

  defp execute_step(session, step, step_index) do
    execute_step(session, step)
  rescue
    exception in StepExecutionError ->
      reraise(exception, __STACKTRACE__)

    exception ->
      raise StepExecutionError,
        failed_step_index: step_index,
        failed_op: step["op"],
        message: Exception.message(exception)
  end

  defp execute_step(session, %{"op" => "fill_in", "label" => label, "value" => value} = step) do
    opts = [with: value, exact: Map.get(step, "exact", true)]

    case Map.get(step, "selector") do
      nil -> PhoenixTest.fill_in(session, label, opts)
      selector -> PhoenixTest.fill_in(session, selector, label, opts)
    end
  end

  defp execute_step(session, %{"op" => op, "label" => label} = step) when op in ["check", "uncheck", "choose"] do
    opts = [exact: Map.get(step, "exact", true)]

    case {op, Map.get(step, "selector")} do
      {"check", nil} -> PhoenixTest.check(session, label, opts)
      {"check", selector} -> PhoenixTest.check(session, selector, label, opts)
      {"uncheck", nil} -> PhoenixTest.uncheck(session, label, opts)
      {"uncheck", selector} -> PhoenixTest.uncheck(session, selector, label, opts)
      {"choose", nil} -> PhoenixTest.choose(session, label, opts)
      {"choose", selector} -> PhoenixTest.choose(session, selector, label, opts)
    end
  end

  defp execute_step(session, %{"op" => "select", "from" => from, "option" => option} = step) do
    opts = [
      option: option,
      exact: Map.get(step, "exact", true),
      exact_option: Map.get(step, "exact_option", true)
    ]

    case Map.get(step, "selector") do
      nil -> PhoenixTest.select(session, from, opts)
      selector -> PhoenixTest.select(session, selector, from, opts)
    end
  end

  defp execute_step(session, %{"op" => "click_button", "text" => text} = step) do
    case Map.get(step, "selector") do
      nil -> PhoenixTest.click_button(session, text)
      selector -> PhoenixTest.click_button(session, selector, text)
    end
  end

  defp execute_step(session, %{"op" => "submit"}) do
    PhoenixTest.submit(session)
  end

  defp execute_step(_session, step) do
    raise StepExecutionError,
      failed_op: step["op"] || "unknown",
      message: "Unsupported step for PhoenixTest execution: #{inspect(step)}"
  end

  defp split_within_block([], _depth, _acc) do
    raise StepExecutionError,
      failed_op: "within",
      message: "Missing within/pop while executing step block"
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
