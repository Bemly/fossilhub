(() => {
  const form = document.querySelector("[data-catalog-form]");
  const current = document.querySelector("[data-catalog-results]");
  if (!form || !current || !window.FossilHub) return;

  const query = form.elements.q;
  const sort = form.elements.sort;
  const kindInput = form.querySelector("[data-kind-input]");
  const state = form.querySelector("[data-search-state]");
  const endpoint = `${window.FossilHub.hubBase}/catalog-fragment`;
  let timer = 0;
  let request = null;

  const parameters = () => new URLSearchParams(new FormData(form));

  const run = async () => {
    if (request) request.abort();
    request = new AbortController();
    form.classList.add("loading");
    state.textContent = "surveying…";
    try {
      const params = parameters();
      const response = await fetch(`${endpoint}?${params}`, {
        headers: { "X-FossilHub-Fragment": "1" },
        signal: request.signal,
      });
      if (!response.ok) throw new Error(`catalogue ${response.status}`);
      const template = document.createElement("template");
      template.innerHTML = (await response.text()).trim();
      const next = template.content.firstElementChild;
      if (!next || !next.matches("[data-catalog-results]")) {
        throw new Error("invalid catalogue fragment");
      }
      document.querySelector("[data-catalog-results]").replaceWith(next);
      next.querySelectorAll(".reveal").forEach((element) => {
        element.classList.add("in");
      });
      const count = Number(next.dataset.resultCount || 0);
      state.textContent = `${count} ${count === 1 ? "match" : "matches"}`;
      history.replaceState(null, "", `${window.FossilHub.hubBase}/explore?${params}`);
      document.dispatchEvent(new CustomEvent("fossilhub:catalog-updated"));
    } catch (error) {
      if (error.name !== "AbortError") state.textContent = "survey unavailable";
    } finally {
      form.classList.remove("loading");
    }
  };

  const schedule = () => {
    clearTimeout(timer);
    timer = window.setTimeout(run, 180);
  };

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    run();
  });
  query.addEventListener("input", schedule);
  sort.addEventListener("change", run);
  form.querySelectorAll("[data-kind]").forEach((button) => {
    button.addEventListener("click", () => {
      kindInput.value = button.dataset.kind;
      form.querySelectorAll("[data-kind]").forEach((item) => {
        item.classList.toggle("sel", item === button);
      });
      run();
    });
  });
  addEventListener("keydown", (event) => {
    if (event.key === "/" && document.activeElement !== query) {
      event.preventDefault();
      query.focus();
    }
  });
})();
