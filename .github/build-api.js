const fs = require("fs");
const path = require("path");
const zlib = require("node:zlib");
const { createRequire } = require("module");
const { minifyHTML } = require("../dashboard/build");
const dashboardDir = path.resolve(__dirname, "../dashboard");
const repositoryDir = path.resolve(__dirname, "..");
const dashboardRequire = createRequire(path.join(dashboardDir, "package.json"));
const luamin = dashboardRequire("luamin");

const HTML_GZIP_PLACEHOLDER = "__HTML_GZIP_PLACEHOLDER__";

async function build() {
  console.log("Starting SKeen API build...");

  const dashboardHtmlPath = path.join(dashboardDir, "index.html");
  const dashboardOutputPath = path.join(dashboardDir, "index.min.html");
  const apiTemplatePath = path.join(repositoryDir, "skeen-api.lua");
  const apiVersionPath = path.join(repositoryDir, "api-version");
  const apiOutputPath = path.join(repositoryDir, "skeen-api");

  if (!fs.existsSync(dashboardHtmlPath)) {
    throw new Error("dashboard/index.html not found!");
  }

  if (!fs.existsSync(apiTemplatePath)) {
    throw new Error("skeen-api.lua not found!");
  }

  if (!fs.existsSync(apiVersionPath)) {
    throw new Error("api-version not found!");
  }

  // 1. Minify dashboard HTML.
  const minHtml = await minifyHTML(
    dashboardHtmlPath,
    dashboardOutputPath,
  );

  const minHtmlBuffer = Buffer.from(minHtml, "utf8");

  // 2. Compress HTML once during build.
  const gzipHtml = zlib.gzipSync(minHtmlBuffer, {
    level: zlib.constants.Z_BEST_COMPRESSION,
    mtime: 0,
  });

  // 3. Encode gzip data as Base64.
  // Base64 uses only characters safe inside a Lua string literal.
  const gzipBase64 = gzipHtml.toString("base64");

  console.log(
    `HTML gzip (${minHtmlBuffer.length} -> ${gzipHtml.length} bytes, ` +
    `${((1 - gzipHtml.length / minHtmlBuffer.length) * 100).toFixed(1)}% smaller)`,
  );

  console.log(
    `Gzip Base64 (${gzipHtml.length} -> ${Buffer.byteLength(gzipBase64)} bytes)`,
  );

  // 4. Read and validate API version.
  const version = fs
    .readFileSync(apiVersionPath, "utf8")
    .trim()
    .replace(/^v/, "");

  if (!/^\d+\.\d+\.\d+[A-Za-z0-9.-]*$/.test(version)) {
    throw new Error(`Invalid API version in api-version: ${version}`);
  }

  // 5. Read Lua template.
  const luaTemplate = fs.readFileSync(apiTemplatePath, "utf8");

  const versionPattern = /local VERSION = "[^"]+"/;

  if (!versionPattern.test(luaTemplate)) {
    throw new Error(
      "Could not find the API version declaration in skeen-api.lua",
    );
  }

  const placeholderCount =
    luaTemplate.split(HTML_GZIP_PLACEHOLDER).length - 1;

  if (placeholderCount !== 1) {
    throw new Error(
      `Expected exactly one HTML gzip placeholder, found ${placeholderCount}`,
    );
  }

  const versionedLuaTemplate = luaTemplate.replace(
    versionPattern,
    `local VERSION = "${version}"`,
  );

  // 6. Minify Lua BEFORE inserting the Base64 data.
  console.log("Minifying Lua script...");

  let minifiedLua;

  const shebangMatch = versionedLuaTemplate.match(
    /^#![^\r\n]*(?:\r?\n|$)/,
  );

  const shebang = shebangMatch ? shebangMatch[0] : "";

  const luaCode = shebang
    ? versionedLuaTemplate.slice(shebang.length)
    : versionedLuaTemplate;

  try {
    minifiedLua = luamin.minify(luaCode);
  } catch (err) {
    console.warn(
      "AST minification failed, using fallback cleanup:",
      err.message,
    );

    minifiedLua = luaCode
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("--"))
      .join("\n");
  }

  // 7. Replace the placeholder AFTER Lua minification.
  const placeholderPattern = /(["'])__HTML_GZIP_PLACEHOLDER__\1/g;
  const placeholderMatches = minifiedLua.match(placeholderPattern) || [];

  if (placeholderMatches.length !== 1) {
    throw new Error(
      `Expected exactly one minified HTML gzip placeholder, found ${placeholderMatches.length}`,
    );
  }

  const cleanLua =
    shebang +
    minifiedLua.replace(
      placeholderPattern,
      () => `"${gzipBase64}"`,
    );

  // 8. Write final Lua script.
  const templateSize = Buffer.byteLength(versionedLuaTemplate);
  const outputSize = Buffer.byteLength(cleanLua);

  console.log(
    `Lua minified (${templateSize} -> ${outputSize} bytes)`,
  );

  fs.writeFileSync(apiOutputPath, cleanLua, "utf8");

  console.log(
    `Done! Release file skeen-api created (${outputSize} bytes).`,
  );
}

build().catch((err) => {
  console.error("Critical build error:", err);
  process.exit(1);
});
