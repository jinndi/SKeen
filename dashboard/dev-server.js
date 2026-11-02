const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");

const host = "127.0.0.1";
const port = Number.parseInt(process.env.PORT || "4173", 10);
const templatePath = path.join(__dirname, "index.html");
const reloadClients = new Set();
let reloadTimeout = null;

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error(`Invalid PORT: ${process.env.PORT}`);
}

const server = http.createServer((request, response) => {
  const pathname = new URL(request.url, `http://${host}`).pathname;
  if (request.method === "GET" && pathname === "/__dev_reload") {
    response.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive"
    });
    response.write(": connected\n\n");
    reloadClients.add(response);
    response.on("close", () => reloadClients.delete(response));
    return;
  }

  if (request.method !== "GET" || (pathname !== "/" && pathname !== "/index.html")) {
    response.writeHead(404);
    response.end("Not found");
    return;
  }

  try {
    const source = fs.readFileSync(templatePath, "utf8");
    const reloadScript = '<script>new EventSource("/__dev_reload").onmessage=()=>location.reload();</script>';
    const html = source.replace("</body>", `${reloadScript}</body>`);
    response.writeHead(200, {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store"
    });
    response.end(html);
  } catch (error) {
    console.error("Failed to serve dashboard:", error);
    response.writeHead(500);
    response.end("Failed to build dashboard source");
  }
});

const watcher = fs.watch(__dirname, (eventType, filename) => {
  if (filename && filename.toString() !== path.basename(templatePath)) return;

  clearTimeout(reloadTimeout);
  reloadTimeout = setTimeout(() => {
    for (const client of reloadClients) client.write("data: reload\n\n");
  }, 100);
});

watcher.on("error", error => {
  console.error("Failed to watch dashboard source:", error);
});

server.listen(port, host, () => {
  console.log(`Dashboard dev server running at http://${host}:${port}`);
});
