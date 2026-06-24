import express from "express";
import http from "node:http";

import { config } from "./config.js";
import { closePool, getRecords, readinessCheck } from "./db.js";

const app = express();

app.get("/", (_req, res) => {
  res.json({
    service: "records-api",
    status: "ok",
    endpoints: ["/healthz", "/readyz", "/api/records"]
  });
});

app.get("/healthz", (_req, res) => {
  res.status(200).json({ status: "healthy" });
});

app.get("/readyz", async (_req, res) => {
  try {
    await readinessCheck();
    res.status(200).json({ status: "ready" });
  } catch (error) {
    console.error("Readiness check failed", error);
    res.status(503).json({ status: "not-ready" });
  }
});

app.get("/api/records", async (_req, res) => {
  try {
    const records = await getRecords();
    res.status(200).json({
      count: records.length,
      records
    });
  } catch (error) {
    console.error("Failed to fetch records", error);
    res.status(500).json({
      error: "Unable to fetch records from the database"
    });
  }
});

const server = http.createServer(app);

server.listen(config.port, () => {
  console.log(`records-api listening on port ${config.port}`);
});

async function shutdown(signal: string): Promise<void> {
  console.log(`Received ${signal}. Starting graceful shutdown.`);

  server.close(async (error) => {
    if (error) {
      console.error("HTTP server shutdown failed", error);
      process.exitCode = 1;
    }

    try {
      await closePool();
    } catch (poolError) {
      console.error("PostgreSQL pool shutdown failed", poolError);
      process.exitCode = 1;
    } finally {
      process.exit();
    }
  });
}

process.on("SIGINT", () => {
  void shutdown("SIGINT");
});

process.on("SIGTERM", () => {
  void shutdown("SIGTERM");
});

