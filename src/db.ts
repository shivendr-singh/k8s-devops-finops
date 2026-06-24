import pg from "pg";

import { config } from "./config.js";

const { Pool } = pg;

export type WorkloadRecord = {
  id: number;
  name: string;
  category: string;
  monthly_cost: string;
  updated_at: string;
};

export const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.database,
  user: config.db.user,
  password: config.db.password,
  max: config.db.max,
  idleTimeoutMillis: config.db.idleTimeoutMillis,
  connectionTimeoutMillis: config.db.connectionTimeoutMillis
});

pool.on("error", (error: Error) => {
  console.error("Unexpected PostgreSQL pool error", error);
});

export async function getRecords(): Promise<WorkloadRecord[]> {
  const result = await pool.query<WorkloadRecord>(
    `
      SELECT id, name, category, monthly_cost, updated_at
      FROM finops_workloads
      ORDER BY id
    `
  );

  return result.rows;
}

export async function readinessCheck(): Promise<void> {
  await pool.query("SELECT 1");
}

export async function closePool(): Promise<void> {
  await pool.end();
}
