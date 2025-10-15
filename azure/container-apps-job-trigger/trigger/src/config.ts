export type Config = {
  environment: string;
  version: string;
  sentryDsn: string;
  sentryEnv: string;
  azureJobResourceId: string;
};

export function createEnvConfig(): Config {
  const env = getEnvValues([
    'ENVIRONMENT',
    'VERSION',
    'SENTRY_DSN',
    'SENTRY_ENV',
    'AZURE_JOB_RESOURCE_ID',
  ]);

  return {
    environment: env.ENVIRONMENT,
    version: env.VERSION,
    sentryDsn: env.SENTRY_DSN,
    sentryEnv: env.SENTRY_ENV,
    azureJobResourceId: env.AZURE_JOB_RESOURCE_ID,
  };
}

/**
 * Used to ensure that the required environment variables are defined.
 *
 * @throws Error containing the names of the missing env variables if any given
 * env from 'keys' is undefined.
 *
 * @example
 * How to use this function:
 * ```
 * const keys = ['API_KEY'] as const;
 * // Returns { API_KEY: 'valueOfYourKeyHere' }
 * const values = getEnvValues(keys);
 * ```
 */
export const getEnvValues = <Keys extends readonly string[]>(keys: Keys) => {
  const missing = keys.filter((key) => process.env[key] === undefined);
  if (missing.length) {
    throw new Error(`Missing required env vars: ${missing.join(', ')}`);
  }
  const envValues: Record<string, string> = {};
  keys.forEach((key) => {
    // assume/assert string type since we filtered undefined values just before this
    envValues[key] = process.env[key] as string;
  });
  // assert type since we added an attribute for each item in our list of keys
  // and made sure that it is a string.
  return envValues as Record<Keys[number], string>;
};
