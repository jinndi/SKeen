const fs = require("fs");
const path = require("path");
const { minify: minifyHtml } = require("html-minifier-terser");

async function minifyEmbeddedTemplates(html) {
  const { minify: minifyTemplates } = await import("esbuild-minify-templates");

  const scriptRegex = /(<script\b[^>]*>)([\s\S]*?)(<\/script\s*>)/gi;
  const matches = [...html.matchAll(scriptRegex)];

  let result = html;

  for (const match of matches.reverse()) {
    const openingTag = match[1];
    const scriptContent = match[2];

    if (!scriptContent.trim()) {
      continue;
    }

    const typeMatch = openingTag.match(/\btype\s*=\s*(['"])(.*?)\1/i);
    const type = typeMatch ? typeMatch[2].toLowerCase() : "";

    if (type && !["text/javascript", "application/javascript", "module"].includes(type)) {
      continue;
    }

    const start = match.index + openingTag.length;
    const minifiedScript = minifyTemplates(scriptContent).toString();

    result = result.slice(0, start) + minifiedScript + result.slice(start + scriptContent.length);
  }

  return result;
}

async function minifyHTML(inputPath, outputPath) {
  const htmlRaw = fs.readFileSync(inputPath, "utf8");

  const htmlWithMinifiedTemplates = await minifyEmbeddedTemplates(htmlRaw);

  const minHtml = await minifyHtml(htmlWithMinifiedTemplates, {
    collapseWhitespace: true,
    removeComments: true,
    minifyCSS: true,
    minifyJS: true,
    keepClosingSlash: true,
  });

  fs.writeFileSync(outputPath, minHtml, "utf8");

  console.log(
    `HTML minified (${Buffer.byteLength(htmlRaw)} -> ${Buffer.byteLength(minHtml)} bytes)`,
  );
  console.log(`Minified HTML saved to ${outputPath}`);

  return minHtml;
}

if (require.main === module) {
  const inputPath = path.resolve(process.argv[2] || "index.html");
  const outputPath = path.resolve(process.argv[3] || "index.min.html");

  minifyHTML(inputPath, outputPath).catch((err) => {
    console.error("HTML minification failed:", err);
    process.exitCode = 1;
  });
}

module.exports = { minifyHTML };
