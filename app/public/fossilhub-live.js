(() => {
  const pathname = window.location.pathname.replace(/\/+$/, "");
  const pageSuffixes = [
    "/repo/dig.fossil",
    "/repo.html",
    "/explore.html",
    "/explore",
    "/index.html",
  ];

  let hubBase = pathname;
  for (const suffix of pageSuffixes) {
    if (pathname.endsWith(suffix)) {
      hubBase = pathname.slice(0, -suffix.length);
      break;
    }
  }

  const repositoryBase = `${hubBase}/fossil/dig`;
  document.querySelectorAll("[data-fossil-path]").forEach((link) => {
    link.href = `${repositoryBase}${link.dataset.fossilPath}`;
  });

  const cloneCommand = `fossil clone ${window.location.origin}${repositoryBase}`;
  document.querySelectorAll("[data-clone-command]").forEach((node) => {
    node.textContent = cloneCommand;
  });
})();
