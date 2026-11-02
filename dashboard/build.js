const fs = require("fs");
const path = require("path");
const htmlnano = require("htmlnano");

async function minifyHTML(inputPath, outputPath) {
  const htmlRaw = fs.readFileSync(inputPath, "utf8");

  const { html: minHtml } = await htmlnano.process(
    htmlRaw,
    {
      skipConfigLoading: true,
      minifyHtmlTemplate: false,
      minifyJson: false,
      minifySvg: false,
    },
    htmlnano.presets.safe,
  );

  fs.writeFileSync(outputPath, minHtml, "utf8");

  console.log(
    `HTML minified (${Buffer.byteLength(htmlRaw)} -> ${Buffer.byteLength(minHtml)} bytes)`,
  );
  console.log(`Minified HTML saved to ${outputPath}`);

  return minHtml;
}

if (require.main === module) {
  const inputPath = path.resolve(process.argv[2] || path.join(__dirname, "index.html"));
  const outputPath = path.resolve(process.argv[3] || path.join(__dirname, "index.min.html"));

  minifyHTML(inputPath, outputPath).catch((err) => {
    console.error("HTML minification failed:", err);
    process.exitCode = 1;
  });
}

module.exports = { minifyHTML };
