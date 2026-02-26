defmodule PhoenixTest.OracleRunner do
  @moduledoc false

  @runner Path.expand("oracle/playwright_oracle_runner.mjs", __DIR__)
  @playwright_probe """
  const fs = require("node:fs");
  const path = require("node:path");
  const { createRequire } = require("node:module");
  const req = createRequire(process.cwd() + "/test/support/oracle/playwright_oracle_runner.mjs");

  let playwright = null;
  const candidates = [
    "playwright",
    path.join(process.cwd(), "priv/static/assets/node_modules/playwright")
  ];

  for (const candidate of candidates) {
    try {
      playwright = req(candidate);
      break;
    } catch (_error) {
      // try next
    }
  }

  if (!playwright) {
    process.exit(11);
  }

  const executable = playwright.chromium.executablePath();
  process.exit(executable && fs.existsSync(executable) ? 0 : 12);
  """

  def base_url do
    endpoint = Application.fetch_env!(:phoenix_test, :endpoint)
    endpoint_config = Application.fetch_env!(:phoenix_test, endpoint)
    url_config = endpoint_config[:url] || []
    http_config = endpoint_config[:http] || []
    scheme = Keyword.get(url_config, :scheme, "http")
    host = Keyword.get(url_config, :host, "localhost")
    port = Keyword.get(url_config, :port, Keyword.get(http_config, :port, 4000))
    "#{scheme}://#{host}:#{port}"
  end

  def available?, do: availability() == :ok

  def availability do
    cond do
      not File.exists?(@runner) ->
        {:error, :runner_not_found}

      is_nil(System.find_executable("node")) ->
        {:error, :node_not_found}

      true ->
        case playwright_probe() do
          :ok -> :ok
          :playwright_not_available -> {:error, :playwright_not_available}
          :playwright_browser_not_available -> {:error, :playwright_browser_not_available}
        end
    end
  end

  def run!(spec) when is_map(spec) do
    case run(spec) do
      {:ok, result} -> result
      {:error, reason} -> raise RuntimeError, message: format_error(reason)
    end
  end

  def run(spec) when is_map(spec) do
    with :ok <- availability() do
      input_path = temp_input_path()
      timeout_ms = oracle_timeout_ms()

      try do
        File.write!(input_path, Jason.encode!(spec))
        cmd_opts = [stderr_to_stdout: true, env: node_env()]

        case system_cmd_with_timeout("node", [@runner, input_path], cmd_opts, timeout_ms) do
          {:ok, {output, status}} -> decode_output(output, status)
          {:error, :timeout} -> {:error, {:runner_timeout, timeout_ms}}
        end
      after
        File.rm(input_path)
      end
    end
  rescue
    exception ->
      {:error, {:exception, exception}}
  end

  defp temp_input_path do
    Path.join(
      System.tmp_dir!(),
      "phoenix_test_oracle_#{System.unique_integer([:positive, :monotonic])}.json"
    )
  end

  defp node_env do
    existing_node_path = System.get_env("NODE_PATH")
    bundled_node_modules = Path.join(File.cwd!(), "priv/static/assets/node_modules")
    separator = if match?({:win32, _}, :os.type()), do: ";", else: ":"

    node_path =
      [bundled_node_modules, existing_node_path]
      |> Enum.reject(&is_nil_or_empty/1)
      |> Enum.join(separator)

    [{"NODE_PATH", node_path}]
  end

  defp playwright_probe do
    timeout_ms = min(oracle_timeout_ms(), 5_000)
    cmd_opts = [stderr_to_stdout: true, env: node_env()]

    case system_cmd_with_timeout("node", ["-e", @playwright_probe], cmd_opts, timeout_ms) do
      {:ok, {_output, 0}} -> :ok
      {:ok, {_output, 11}} -> :playwright_not_available
      {:ok, {_output, _status}} -> :playwright_browser_not_available
      {:error, :timeout} -> :playwright_browser_not_available
    end
  end

  defp decode_output(output, status) do
    case Jason.decode(output) do
      {:ok, %{"ok" => true} = payload} when status == 0 ->
        {:ok, payload}

      {:ok, %{"ok" => false} = payload} ->
        {:error, {:runner_failed, status, payload}}

      {:ok, payload} ->
        {:error, {:unexpected_payload, status, payload}}

      {:error, decode_error} ->
        {:error, {:invalid_json, status, output, decode_error}}
    end
  end

  defp format_error({:runner_not_found}), do: "Oracle runner file was not found at #{@runner}"
  defp format_error({:node_not_found}), do: "Node executable was not found"
  defp format_error({:playwright_not_available}), do: "Playwright package is not available to Node"

  defp format_error({:playwright_browser_not_available}),
    do: "Playwright browser binaries are not installed (run playwright install chromium)"

  defp format_error({:runner_failed, status, payload}) do
    "Oracle runner failed with status #{status}: #{inspect(payload, pretty: true, limit: :infinity)}"
  end

  defp format_error({:runner_timeout, timeout_ms}), do: "Oracle runner timed out after #{timeout_ms}ms"

  defp format_error({:unexpected_payload, status, payload}) do
    "Oracle runner returned unexpected payload with status #{status}: #{inspect(payload, pretty: true, limit: :infinity)}"
  end

  defp format_error({:invalid_json, status, output, decode_error}) do
    "Oracle runner returned invalid JSON with status #{status}: #{inspect(decode_error)} output=#{inspect(output)}"
  end

  defp format_error({:exception, exception}) do
    "Oracle runner wrapper raised: #{Exception.message(exception)}"
  end

  defp format_error(other), do: "Oracle runner failed: #{inspect(other)}"

  defp is_nil_or_empty(nil), do: true
  defp is_nil_or_empty(""), do: true
  defp is_nil_or_empty(_), do: false

  defp oracle_timeout_ms do
    case Integer.parse(System.get_env("PHOENIX_TEST_ORACLE_TIMEOUT_MS", "10000")) do
      {ms, ""} when ms > 0 -> ms
      _ -> 10_000
    end
  end

  defp system_cmd_with_timeout(command, args, opts, timeout_ms) do
    task = Task.async(fn -> System.cmd(command, args, opts) end)

    try do
      {:ok, Task.await(task, timeout_ms)}
    catch
      :exit, {:timeout, _} ->
        Task.shutdown(task, :brutal_kill)
        {:error, :timeout}
    end
  end
end
