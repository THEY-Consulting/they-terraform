export type Config = {
  azureJobResourceId: string;
};

export function createEnvConfig(): Config {
  const azureJobResourceId = process.env.AZURE_JOB_RESOURCE_ID;
  if (!azureJobResourceId) {
    throw new Error('Missing required env var: AZURE_JOB_RESOURCE_ID');
  }

  return {
    azureJobResourceId,
  };
}
