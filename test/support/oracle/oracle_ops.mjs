const DEFAULT_TIMEOUT_MS = 5_000;

function currentScope(page, scopeStack) {
  return scopeStack.length > 0 ? scopeStack[scopeStack.length - 1] : page;
}

function toExact(step) {
  return step.exact !== false;
}

async function ensureSubmitObserver(page) {
  await page.evaluate(() => {
    if (window.__phoenixTestOracleSubmitObserverInstalled) {
      return;
    }

    const normalizeMethodInner = (methodAttr) => {
      const value =
        typeof methodAttr === "string" ? methodAttr.trim().toLowerCase() : "";
      return value || "get";
    };

    const normalizeActionInner = (actionAttr) => {
      if (typeof actionAttr !== "string" || actionAttr.trim() === "") {
        return `${window.location.pathname}${window.location.search}`;
      }

      try {
        const url = new URL(actionAttr, document.baseURI);
        return `${url.pathname}${url.search}`;
      } catch {
        return actionAttr;
      }
    };

    const serializeValueInner = (value) => {
      if (typeof value === "string") {
        return value;
      }

      if (value && typeof value === "object" && "name" in value) {
        return value.name;
      }

      return String(value);
    };

    window.__phoenixTestOracleLastSubmit = null;

    document.addEventListener(
      "submit",
      (event) => {
        const form = event.target;

        if (!(form instanceof HTMLFormElement)) {
          return;
        }

        event.preventDefault();

        const submitter =
          event.submitter instanceof HTMLElement ? event.submitter : null;

        let formData;
        try {
          formData = submitter
            ? new FormData(form, submitter)
            : new FormData(form);
        } catch {
          formData = new FormData(form);
        }

        const methodAttr =
          submitter?.getAttribute?.("formmethod") ??
          form.getAttribute("method");
        const actionAttr =
          submitter?.getAttribute?.("formaction") ??
          form.getAttribute("action");

        window.__phoenixTestOracleLastSubmit = {
          submitted: true,
          submitter: submitter
            ? {
                tag: submitter.tagName.toLowerCase(),
                type: submitter.getAttribute("type") || null,
                name: submitter.getAttribute("name") || null,
                value: submitter.getAttribute("value") || null,
                id: submitter.id || null,
              }
            : null,
          entries: Array.from(formData.entries()).map(([name, value]) => [
            name,
            serializeValueInner(value),
          ]),
          effective_method: normalizeMethodInner(methodAttr),
          effective_action: normalizeActionInner(actionAttr),
          form_selector: form.id ? `#${form.id}` : null,
        };
      },
      true,
    );

    window.__phoenixTestOracleSubmitObserverInstalled = true;
  });
}

async function resolveLabelLocator(scope, label, exact) {
  const locator = scope.getByLabel(label, { exact });
  await locator
    .first()
    .waitFor({ state: "attached", timeout: DEFAULT_TIMEOUT_MS });
  return locator;
}

async function ensureSelectorMatch(locator, selector, reason) {
  const matches = await locator
    .first()
    .evaluate(
      (element, selectorValue) => element.matches(selectorValue),
      selector,
    );

  if (!matches) {
    throw new Error(reason);
  }
}

async function resolveOptionValuesForPartialMatch(selectLocator, optionInput) {
  const selectedValues = await selectLocator.evaluate(
    (selectElement, optionValue) => {
      if (!(selectElement instanceof HTMLSelectElement)) {
        throw new Error("Expected a <select> element");
      }

      const wanted = Array.isArray(optionValue) ? optionValue : [optionValue];

      return wanted.map((item) => {
        const loweredItem = String(item).toLowerCase();
        const option = Array.from(selectElement.options).find((candidate) => {
          const text = (candidate.label || candidate.text || "").toLowerCase();
          const value = (candidate.value || "").toLowerCase();
          return text.includes(loweredItem) || value.includes(loweredItem);
        });

        return option ? option.value : null;
      });
    },
    optionInput,
  );

  if (selectedValues.some((value) => value === null)) {
    throw new Error(
      `Could not resolve option value for ${JSON.stringify(optionInput)}`,
    );
  }

  return Array.isArray(optionInput) ? selectedValues : selectedValues[0];
}

async function executeStep(page, scopeStack, step, state) {
  switch (step.op) {
    case "within": {
      if (step.mode === "push") {
        if (!step.selector) {
          throw new Error("within push requires selector");
        }

        const locator = currentScope(page, scopeStack)
          .locator(step.selector)
          .first();
        await locator.waitFor({
          state: "attached",
          timeout: DEFAULT_TIMEOUT_MS,
        });
        scopeStack.push(locator);
        return;
      }

      if (step.mode === "pop") {
        if (scopeStack.length === 0) {
          throw new Error("within pop called with empty scope stack");
        }

        scopeStack.pop();
        return;
      }

      throw new Error(`Unsupported within mode: ${step.mode}`);
    }

    case "fill_in": {
      const locator = await resolveLabelLocator(
        currentScope(page, scopeStack),
        step.label,
        toExact(step),
      );

      if (step.selector) {
        await ensureSelectorMatch(
          locator,
          step.selector,
          "fill_in selector does not match labeled control",
        );
      }

      await locator.fill(String(step.value));
      return;
    }

    case "check":
    case "choose": {
      const locator = await resolveLabelLocator(
        currentScope(page, scopeStack),
        step.label,
        toExact(step),
      );

      if (step.selector) {
        await ensureSelectorMatch(
          locator,
          step.selector,
          "check selector does not match labeled control",
        );
      }

      await locator.check();
      return;
    }

    case "uncheck": {
      const locator = await resolveLabelLocator(
        currentScope(page, scopeStack),
        step.label,
        toExact(step),
      );

      if (step.selector) {
        await ensureSelectorMatch(
          locator,
          step.selector,
          "uncheck selector does not match labeled control",
        );
      }

      await locator.uncheck();
      return;
    }

    case "select": {
      const locator = await resolveLabelLocator(
        currentScope(page, scopeStack),
        step.from,
        toExact(step),
      );

      if (step.selector) {
        await ensureSelectorMatch(
          locator,
          step.selector,
          "select selector does not match labeled control",
        );
      }

      const exactOption = step.exact_option !== false;

      if (exactOption) {
        const options = Array.isArray(step.option)
          ? step.option.map((option) => ({ label: String(option) }))
          : { label: String(step.option) };

        await locator.selectOption(options);
      } else {
        const optionValues = await resolveOptionValuesForPartialMatch(
          locator,
          step.option,
        );
        await locator.selectOption(optionValues);
      }

      return;
    }

    case "click_button": {
      const button = currentScope(page, scopeStack).getByRole("button", {
        name: step.text,
        exact: toExact(step),
      });

      if (step.selector) {
        await ensureSelectorMatch(
          button,
          step.selector,
          "click_button selector does not match button",
        );
      }

      await page.evaluate(() => {
        window.__phoenixTestOracleLastSubmit = null;
      });

      await button.click();
      state.lastSubmitResult = await page.evaluate(
        () => window.__phoenixTestOracleLastSubmit ?? null,
      );
      return;
    }

    case "submit": {
      await page.evaluate(
        ({ formSelector, submitterSelector }) => {
          window.__phoenixTestOracleLastSubmit = null;

          const form = formSelector
            ? document.querySelector(formSelector)
            : document.querySelector("form");

          if (!(form instanceof HTMLFormElement)) {
            throw new Error(
              `Unable to find form for selector: ${formSelector ?? "<first-form>"}`,
            );
          }

          let submitter = null;

          if (submitterSelector) {
            submitter = document.querySelector(submitterSelector);

            if (!(submitter instanceof HTMLElement)) {
              throw new Error(
                `Unable to find submitter for selector: ${submitterSelector}`,
              );
            }
          }

          form.requestSubmit(submitter || undefined);
        },
        {
          formSelector: step.form_selector ?? null,
          submitterSelector: step.submitter_selector ?? null,
        },
      );

      state.lastSubmitResult = await page.evaluate(
        () => window.__phoenixTestOracleLastSubmit ?? null,
      );
      return;
    }

    default:
      throw new Error(`Unsupported op: ${step.op}`);
  }
}

function buildStepError(error, stepIndex, step) {
  const wrappedError = new Error(error?.message || String(error));
  wrappedError.name = "OracleStepError";
  wrappedError.stepIndex = stepIndex;
  wrappedError.failedOp = step?.op ?? null;
  wrappedError.playwrightError = error?.message || String(error);
  wrappedError.stack = error?.stack || wrappedError.stack;
  return wrappedError;
}

export async function runSteps(page, steps, trace, state = {}) {
  const scopeStack = [];
  const normalizedSteps = Array.isArray(steps) ? steps : [];

  for (let stepIndex = 0; stepIndex < normalizedSteps.length; stepIndex += 1) {
    const step = normalizedSteps[stepIndex];

    try {
      await ensureSubmitObserver(page);
      await executeStep(page, scopeStack, step, state);

      trace.push({
        index: stepIndex,
        op: step.op,
        scope_depth: scopeStack.length,
        status: "ok",
      });
    } catch (error) {
      trace.push({
        index: stepIndex,
        op: step?.op ?? "unknown",
        scope_depth: scopeStack.length,
        status: "error",
        message: error?.message || String(error),
      });

      throw buildStepError(error, stepIndex, step);
    }
  }

  await ensureSubmitObserver(page);
}
