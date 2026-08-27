(() => {
  const pathname = window.location.pathname.replace(/\/+$/, "");
  const pageSuffixes = [
    "/repo.html",
    "/explore.html",
    "/explore",
    "/index.html",
  ];

  let hubBase = pathname;
  const repositoryPage = pathname.match(/\/repo\/[^/]+$/);
  if (repositoryPage) {
    hubBase = pathname.slice(0, -repositoryPage[0].length);
  }
  for (const suffix of pageSuffixes) {
    if (pathname.endsWith(suffix)) {
      hubBase = pathname.slice(0, -suffix.length);
      break;
    }
  }

  const repositorySlug = document.body.dataset.repositorySlug || "dig";
  const repositoryBase = `${hubBase}/fossil/${encodeURIComponent(repositorySlug)}`;
  document.querySelectorAll("[data-fossil-path]").forEach((link) => {
    link.href = `${repositoryBase}${link.dataset.fossilPath}`;
  });

  const cloneCommand = `fossil clone ${window.location.origin}${repositoryBase}`;
  document.querySelectorAll("[data-clone-command]").forEach((node) => {
    node.textContent = cloneCommand;
  });
})();
