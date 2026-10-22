// Headless Chrome check for the hot-swap demo.
// Usage: node tools/verify_web.mjs <url> <substring> [timeout-seconds]
// Exits 0 when #hotswap-status contains the substring.

import { spawn } from "node:child_process";
import http from "node:http";

const url = process.argv[2];
const expected = process.argv[3];
const timeoutSec = Number(process.argv[4] || "90");
if (!url || !expected) {
  console.error("Usage: node tools/verify_web.mjs <url> <substring> [timeout-seconds]");
  process.exit(2);
}

const port = 9222 + Math.floor(Math.random() * 1000);
const profile = `/tmp/chrome-hotswap-${port}`;
const chrome = spawn(
  "google-chrome",
  [
    "--headless=new",
    "--no-sandbox",
    "--disable-gpu",
    "--disable-dev-shm-usage",
    `--remote-debugging-port=${port}`,
    `--user-data-dir=${profile}`,
    url,
  ],
  { stdio: ["ignore", "pipe", "pipe"] }
);

let chromeLog = "";
chrome.stdout.on("data", (chunk) => {
  chromeLog += chunk.toString();
});
chrome.stderr.on("data", (chunk) => {
  chromeLog += chunk.toString();
});

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function getJson(path) {
  return new Promise((resolve, reject) => {
    const req = http.get({ hostname: "127.0.0.1", port, path }, (res) => {
      let body = "";
      res.on("data", (chunk) => {
        body += chunk;
      });
      res.on("end", () => {
        try {
          resolve(JSON.parse(body));
        } catch (err) {
          reject(err);
        }
      });
    });
    req.on("error", reject);
  });
}

async function waitForPage() {
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline) {
    try {
      const pages = await getJson("/json/list");
      const page = pages.find((item) => item.type === "page" && item.webSocketDebuggerUrl);
      if (page) return page;
    } catch {
      // Chrome is still starting.
    }
    await sleep(250);
  }
  throw new Error("Chrome did not open a debuggable page");
}

function cdp(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let nextId = 1;
  const pending = new Map();
  const events = [];
  const opened = new Promise((resolve, reject) => {
    ws.addEventListener("open", () => resolve());
    ws.addEventListener("error", () => reject(new Error("CDP socket failed")));
  });
  ws.addEventListener("message", (event) => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const { resolve, reject } = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) reject(new Error(JSON.stringify(message.error)));
      else resolve(message.result);
    } else if (message.method) {
      events.push(message);
    }
  });
  return {
    events,
    ready: opened,
    send(method, params = {}) {
      const id = nextId++;
      ws.send(JSON.stringify({ id, method, params }));
      return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
    },
    close() {
      ws.close();
    },
  };
}

async function main() {
  const page = await waitForPage();
  const client = cdp(page.webSocketDebuggerUrl);
  await client.ready;
  await client.send("Runtime.enable");
  await client.send("Console.enable");
  const deadline = Date.now() + timeoutSec * 1000;
  let last = "";
  while (Date.now() < deadline) {
    const result = await client.send("Runtime.evaluate", {
      expression: "document.getElementById('hotswap-status') ? document.getElementById('hotswap-status').textContent : ''",
      returnByValue: true,
    });
    last = result.result?.value || "";
    if (last.includes(expected)) {
      console.log("STATUS:\n" + last);
      const logs = client.events.filter(
        (event) => event.method === "Runtime.consoleAPICalled" || event.method === "Runtime.exceptionThrown"
      );
      const text = logs.map((event) => JSON.stringify(event.params)).join("\n");
      const bad = text.match(/stream_peer_gzip|err != 0 && err != 1|SCRIPT ERROR|Parse Error/g);
      if (logs.length) {
        console.log(`CONSOLE EVENTS: ${logs.length}`);
        for (const line of logs.slice(-15).map((event) => JSON.stringify(event.params).slice(0, 500))) {
          console.log(line);
        }
      }
      client.close();
      chrome.kill();
      if (bad) {
        console.error("LOADER/SCRIPT ERRORS: " + bad.join(", "));
        process.exit(1);
      }
      process.exit(0);
    }
    await sleep(500);
  }
  console.error("Timed out waiting for status to include:\n" + expected);
  console.error("Last status:\n" + (last || "(empty)"));
  const errors = client.events
    .filter((event) => event.method === "Runtime.exceptionThrown" || event.method === "Runtime.consoleAPICalled")
    .slice(-30);
  console.error("CONSOLE EVENTS:\n" + JSON.stringify(errors, null, 2).slice(0, 4000));
  console.error("CHROME LOG TAIL:\n" + chromeLog.slice(-2000));
  client.close();
  chrome.kill();
  process.exit(1);
}

main().catch((err) => {
  console.error(err);
  chrome.kill();
  process.exit(1);
});
