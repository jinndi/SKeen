const fs = require("fs");
const { minifyHTML } = require("./minify-html");
const luamin = require("luamin");

async function build() {
  console.log("Starting SKeen API build...");

  if (!fs.existsSync("index.html")) {
    console.error("Error: index.html not found!");
    process.exit(1);
  }

  const minHtml = await minifyHTML("index.html", "index.min.html");

  if (!fs.existsSync("skeen-api.lua")) {
    console.error("Error: skeen-api.lua not found!");
    process.exit(1);
  }

  const luaTemplate = fs.readFileSync("skeen-api.lua", "utf8");
  const luaInjected = luaTemplate.replace("__HTML_PLACEHOLDER__", minHtml);

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

  fs.writeFileSync("skeen-api", cleanLua, "utf8");

  console.log(`Done! Release file skeen-api created (${cleanLua.length} bytes).`);
}

build().catch((err) => {
  console.error("Critical build error:", err);
  process.exit(1);
});
