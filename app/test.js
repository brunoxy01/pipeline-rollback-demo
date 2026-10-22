const assert = require("assert");
const http = require("http");
const { handler } = require("./server");

const server = http.createServer(handler).listen(0, () => {
  http.get({ port: server.address().port, path: "/healthz" }, (res) => {
    assert.strictEqual(res.statusCode, 200);
    server.close();
    console.log("ok");
  });
});
