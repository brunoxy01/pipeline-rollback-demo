const http = require("http");

const VERSION = process.env.APP_VERSION || "dev";
// Simula uma versão ruim: FAIL_RATE=0.5 faz 50% das requisições retornarem 500.
const FAIL_RATE = parseFloat(process.env.FAIL_RATE || "0");

function handler(req, res) {
  if (req.url === "/healthz") {
    res.writeHead(200);
    return res.end("ok");
  }
  if (Math.random() < FAIL_RATE) {
    res.writeHead(500, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ error: "simulated failure", version: VERSION }));
  }
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ message: "hello", version: VERSION }));
}

if (require.main === module) {
  const server = http.createServer(handler).listen(8080, () => console.log(`v${VERSION} on :8080`));
  // Como PID 1 do container, o Node não encerra sozinho no SIGTERM; sem isso o pod espera o prazo de 30s.
  for (const signal of ["SIGTERM", "SIGINT"]) {
    process.on(signal, () => {
      server.close(() => process.exit(0));
      server.closeIdleConnections();
      setTimeout(() => process.exit(0), 3000).unref();
    });
  }
}

module.exports = { handler };
