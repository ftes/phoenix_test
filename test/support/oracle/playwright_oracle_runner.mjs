import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createRequire } from "node:module";
import { runSteps } from "./oracle_ops.mjs";
import { captureResult } from "./oracle_capture.mjs";

const require = createRequire(import.meta.url);
const { chromium } = loadPlaywright();
const trace = [];

function loadPlaywright() {
  const candidates = [
    "playwright",
    path.join(process.cwd(), "priv/static/assets/node_modules/playwright"),
  ];

  for (const candidate of candidates) {
    try {
      return require(candidate);
    } catch {
      // try next candidate
    }
  }

  throw new Error(
    "Unable to resolve Playwright. Checked module names: playwright and priv/static/assets/node_modules/playwright",
  );
}

function emit(payload) {
  process.stdout.write(JSON.stringify(payload));
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function shutdownBrowser(browser) {
  if (!browser) {
    return;
  }

  const browserProcess =
    typeof browser.process === "function" ? browser.process() : null;
  let closed = false;

  await Promise.race([
    browser
      .close()
      .then(() => {
        closed = true;
      })
      .catch(() => undefined),
    sleep(500),
  ]);

  if (!closed && browserProcess && !browserProcess.killed) {
    browserProcess.kill("SIGKILL");
  }
}

function validateSpec(spec) {
  if (!spec || typeof spec !== "object") {
    throw new Error("Spec must be a JSON object");
  }

  if (!spec.base_url || !spec.initial_path) {
    throw new Error("Spec must include base_url and initial_path");
  }

  if (!Array.isArray(spec.steps)) {
    throw new Error("Spec must include a steps array");
  }

  if (!spec.capture || typeof spec.capture !== "object") {
    throw new Error("Spec must include capture");
  }
}

function resolveTimeoutMs(spec) {
  const value = Number(spec?.timeout_ms);
  return Number.isFinite(value) && value > 0 ? value : 5_000;
}

async function readSpecFromPath() {
  const inputPath = process.argv[2];

  if (!inputPath) {
    throw new Error("Missing input file path argument");
  }

  const raw = await fs.readFile(inputPath, "utf8");
  return JSON.parse(raw);
}

async function main() {
  let browser;
  let context;
  let page;
  const state = {};

  try {
    const spec = await readSpecFromPath();
    validateSpec(spec);

    browser = await chromium.launch({ headless: true });
    context = await browser.newContext();
    page = await context.newPage();
    page.on("console", (message) => {
      trace.push({
        type: "console",
        level: message.type(),
        text: message.text(),
      });
    });
    page.on("pageerror", (error) => {
      trace.push({
        type: "pageerror",
        message: error?.message ?? String(error),
      });
    });

    const timeoutMs = resolveTimeoutMs(spec);
    page.setDefaultTimeout(timeoutMs);
    page.setDefaultNavigationTimeout(timeoutMs);

    const visitUrl = new URL(spec.initial_path, spec.base_url).toString();
    await page.goto(visitUrl, {
      waitUntil: "domcontentloaded",
      timeout: timeoutMs,
    });

    state.preventSubmitDefault =
      spec?.prevent_submit_default === true ||
      spec?.capture?.type === "submit_result";
    state.stepTimeoutMs = timeoutMs;

    await runSteps(page, spec.steps, trace, state);
    const capture = await captureResult(page, spec.capture, state);

    emit({ ok: true, trace, capture });
  } catch (error) {
    emit({
      ok: false,
      trace,
      failed_step_index: error?.stepIndex ?? null,
      failed_op: error?.failedOp ?? null,
      playwright_error:
        error?.playwrightError ?? error?.message ?? String(error),
      message: error?.message ?? String(error),
      stack: error?.stack ?? null,
    });

    process.exitCode = 1;
  } finally {
    await shutdownBrowser(browser);
  }
}

await main();
