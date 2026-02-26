async function captureFormSnapshot(page, capture) {
  return page.evaluate(
    ({ formSelector }) => {
      const form = formSelector
        ? document.querySelector(formSelector)
        : document.querySelector("form");

      if (!(form instanceof HTMLFormElement)) {
        throw new Error(
          `Unable to find form for selector: ${formSelector ?? "<first-form>"}`,
        );
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

      const methodAttr = form.getAttribute("method");
      const actionAttr = form.getAttribute("action");

      const entries = Array.from(new FormData(form).entries()).map(
        ([name, value]) => [name, serializeValueInner(value)],
      );

      const controls = Array.from(form.elements)
        .map((control) => {
          if (!(control instanceof HTMLElement)) {
            return null;
          }

          const tag = control.tagName.toLowerCase();
          const type =
            control.getAttribute("type") ||
            (tag === "button" ? "submit" : null);
          const name = control.getAttribute("name");

          return {
            tag,
            type: type ? type.toLowerCase() : null,
            name,
            id: control.id || null,
            disabled: control.matches(":disabled"),
            form_owner_id: control.form?.id || null,
          };
        })
        .filter(Boolean);

      return {
        form_selector: formSelector ?? (form.id ? `#${form.id}` : null),
        method_attr: methodAttr,
        action_attr: actionAttr,
        effective_method: normalizeMethodInner(methodAttr),
        effective_action: normalizeActionInner(actionAttr),
        entries,
        controls,
      };
    },
    { formSelector: capture.form_selector ?? null },
  );
}

async function captureSubmitResult(page, state) {
  if (state.lastSubmitResult) {
    return {
      ...state.lastSubmitResult,
      entries: Array.isArray(state.lastSubmitResult.entries)
        ? state.lastSubmitResult.entries
        : [],
    };
  }

  const submitResult = await page.evaluate(
    () => window.__phoenixTestOracleLastSubmit ?? null,
  );

  if (!submitResult) {
    return { submitted: false, submitter: null, entries: [] };
  }

  return {
    ...submitResult,
    entries: Array.isArray(submitResult.entries) ? submitResult.entries : [],
  };
}

export async function captureResult(page, capture, state = {}) {
  if (capture.type === "form_snapshot") {
    return captureFormSnapshot(page, capture);
  }

  if (capture.type === "submit_result") {
    return captureSubmitResult(page, state);
  }

  throw new Error(`Unsupported capture type: ${capture.type}`);
}
