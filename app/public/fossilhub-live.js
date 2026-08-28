(() => {
  const pathname = window.location.pathname.replace(/\/+$/, "");
  let hubBase = pathname;
  const applicationRoute = pathname.match(
    /\/(?:account(?:\/.*)?|admin(?:\/.*)?|users\/[^/]+|settings(?:\/.*)?|repositories\/new|repo\/[^/]+(?:\/.*)?|dashboard|register|logout|login|repo\.html|explore(?:\.html)?|index\.html|manual|hosting|upstream|releases|rules|status|privacy|security|contact)$/,
  );
  if (applicationRoute) {
    hubBase = pathname.slice(0, -applicationRoute[0].length);
  }

  const repositorySlug = document.body.dataset.repositorySlug || "dig";
  const repositoryBase = `${hubBase}/fossil/${encodeURIComponent(repositorySlug)}`;
  window.FossilHub = Object.freeze({ hubBase, repositoryBase });
  document.querySelectorAll("[data-hub-path]").forEach((link) => {
    link.href = `${hubBase}${link.dataset.hubPath}`;
  });
  document.querySelectorAll("form[data-hub-action]").forEach((form) => {
    form.action = `${hubBase}${form.dataset.hubAction}`;
  });
  document.querySelectorAll("[data-fossil-path]").forEach((link) => {
    link.href = `${repositoryBase}${link.dataset.fossilPath}`;
  });

  const cloneCommand = `fossil clone ${window.location.origin}${repositoryBase}`;
  document.querySelectorAll("[data-clone-command]").forEach((node) => {
    node.textContent = cloneCommand;
  });
})();
