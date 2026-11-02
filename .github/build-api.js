const fs = require("fs");
const path = require("path");
const { createRequire } = require("module");
const { minifyHTML } = require("../dashboard/build");
const dashboardDir = path.resolve(__dirname, "../dashboard");
const repositoryDir = path.resolve(__dirname, "..");
const dashboardRequire = createRequire(path.join(dashboardDir, "package.json"));
const luamin = dashboardRequire("luamin");

async function build() {
  console.log("Starting SKeen API build...");

  const dashboardHtmlPath = path.join(dashboardDir, "index.html");
  const dashboardOutputPath = path.join(dashboardDir, "index.min.html");
  const apiTemplatePath = path.join(repositoryDir, "skeen-api.lua");
  const apiVersionPath = path.join(repositoryDir, "api-version");
  const apiOutputPath = path.join(repositoryDir, "skeen-api");

  if (!fs.existsSync(dashboardHtmlPath)) {
    console.error("Error: dashboard/index.html not found!");
    process.exit(1);
  }

  const minHtml = await minifyHTML(dashboardHtmlPath, dashboardOutputPath);

  if (!fs.existsSync(apiTemplatePath)) {
    console.error("Error: skeen-api.lua not found!");
    process.exit(1);
  }

  const version = fs.readFileSync(apiVersionPath, "utf8").trim().replace(/^v/, "");
  if (!/^\d+\.\d+\.\d+[A-Za-z0-9.-]*$/.test(version)) {
    throw new Error(`Invalid API version in api-version: ${version}`);
  }

  const luaTemplate = fs.readFileSync(apiTemplatePath, "utf8");
  const versionPattern = /local VERSION = "[^"]+"/;
  if (!versionPattern.test(luaTemplate)) {
    throw new Error("Could not find the API version declaration in skeen-api.lua");
  }
  const versionedLuaTemplate = luaTemplate.replace(versionPattern, `local VERSION = "${version}"`);
  const luaInjected = versionedLuaTemplate.replace("__HTML_PLACEHOLDER__", minHtml);

  console.log("Minifying Lua script...");

  let cleanLua;

  const shebangMatch = luaInjected.match(/^#![^\r\n]*(?:\r?\n|$)/);
  const shebang = shebangMatch ? shebangMatch[0] : "";
  const luaCode = shebang ? luaInjected.slice(shebang.length) : luaInjected;

  try {
    cleanLua = shebang + luamin.minify(luaCode);

    console.log(`Lua minified (${luaInjected.length} -> ${cleanLua.length} bytes)`);
  } catch (err) {
    console.warn("AST minification failed, using fallback cleanup:", err.message);

    cleanLua =
      shebang +
      luaCode
        .split("\n")
        .map((line) => line.trim())
        .filter((line) => line && !line.startsWith("--"))
        .join("\n");
  }

  fs.writeFileSync(apiOutputPath, cleanLua, "utf8");

  console.log(`Done! Release file skeen-api created (${cleanLua.length} bytes).`);
}

build().catch((err) => {
  console.error("Critical build error:", err);
  process.exit(1);
});
