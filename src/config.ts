function requireEnv(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

function parseNumber(name: string, fallback?: number): number {
  const raw = process.env[name];

  if (!raw) {
    if (fallback === undefined) {
      throw new Error(`Missing required environment variable: ${name}`);
    }
    return fallback;
  }

  const parsed = Number(raw);

  if (Number.isNaN(parsed)) {
    throw new Error(`Environment variable ${name} must be a number`);
  }

  return parsed;
}

export const config = {
  port: parseNumber("PORT", 8080),
  db: {
    host: requireEnv("DB_HOST"),
    port: parseNumber("DB_PORT", 5432),
    database: requireEnv("DB_NAME"),
    user: requireEnv("DB_USER"),
    password: requireEnv("DB_PASSWORD"),
    max: parseNumber("DB_POOL_MAX"),
    idleTimeoutMillis: parseNumber("DB_POOL_IDLE_TIMEOUT_MS"),
    connectionTimeoutMillis: parseNumber("DB_POOL_CONNECTION_TIMEOUT_MS")
  }
};

