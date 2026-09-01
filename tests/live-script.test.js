const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");

const source = fs.readFileSync(
  path.join(__dirname, "..", "app", "public", "fossilhub-live.js"),
  "utf8",
);

function verify(pathname, expectedBase) {
  const links = [{ dataset: { hubPath: "/dashboard" }, href: "" }];
  const forms = [{ dataset: { hubAction: "/logout" }, action: "" }];
  const fossilLinks = [{ dataset: { fossilPath: "/xfer" }, href: "" }];
  const cloneNodes = [{ textContent: "" }];
  const document = {
    body: { dataset: { repositorySlug: "bedrock" } },
    querySelectorAll(selector) {
      if (selector === "[data-hub-path]") return links;
      if (selector === "form[data-hub-action]") return forms;
      if (selector === "[data-fossil-path]") return fossilLinks;
      if (selector === "[data-clone-command]") return cloneNodes;
      return [];
    },
  };
  const window = { location: { pathname, origin: "https://example.test" } };
  vm.runInNewContext(source, { document, window, encodeURIComponent, Object });
  if (window.FossilHub.hubBase !== expectedBase) {
    throw new Error(`${pathname}: expected base ${expectedBase}, got ${window.FossilHub.hubBase}`);
  }
  if (links[0].href !== `${expectedBase}/dashboard`) {
    throw new Error(`${pathname}: mounted link rewrite failed`);
  }
  if (forms[0].action !== `${expectedBase}/logout`) {
    throw new Error(`${pathname}: mounted form rewrite failed`);
  }
  if (!cloneNodes[0].textContent.includes(`${expectedBase}/fossil/bedrock`)) {
    throw new Error(`${pathname}: clone command rewrite failed`);
  }
}

const mount = "/bemly-moe/app/fossilhub";
for (const pathname of [
  mount,
  `${mount}/dashboard`,
  `${mount}/settings/security`,
  `${mount}/users/alice`,
  `${mount}/admin/users/0123456789abcdef0123456789abcdef`,
  `${mount}/admin/repositories/bedrock/integrity`,
  `${mount}/manual`,
  `${mount}/status`,
  `${mount}/repo/bedrock/timeline`,
]) {
  verify(pathname, mount);
}
verify("/dashboard", "");
verify("/repo/bedrock/files", "");

console.log("live script tests passed");
