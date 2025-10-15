import { DefaultAzureCredential } from '@azure/identity';
import { type Config } from './config';
import {
  type EnvironmentVar,
  type JobExecutionResult,
  type JobParams,
  JobConfigurationSchema,
  JobExecutionResponseSchema,
} from './types';
import { validateData } from './validation';

/**
 * Triggers an Azure Container Apps Job with custom parameters
 */
export async function triggerContainerJob(
  config: Config,
  params: JobParams,
): Promise<JobExecutionResult> {
  const credential = new DefaultAzureCredential();
  const apiVersion = '2024-03-01';
  const baseUrl = 'https://management.azure.com';

  // Get access token
  const tokenResponse = await credential.getToken('https://management.azure.com/.default');
  const accessToken = tokenResponse.token;

  // Step 1: Fetch current job configuration
  const jobConfigUrl = `${baseUrl}/subscriptions/${config.azureSubscriptionId}/resourceGroups/${config.azureResourceGroup}/providers/Microsoft.App/jobs/${config.azureJobName}?api-version=${apiVersion}`;

  const configResponse = await fetch(jobConfigUrl, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
  });

  if (!configResponse.ok) {
    const errorText = await configResponse.text();
    throw new Error(`Failed to fetch job configuration: ${configResponse.status} ${errorText}`);
  }

  const jobConfigData = await configResponse.json();
  const jobConfig = validateData(jobConfigData, JobConfigurationSchema);
  const container = jobConfig.properties.template.containers[0];

  if (!container) {
    throw new Error('No container found in job configuration');
  }

  // Step 2: Build environment variables
  // Auto-generate env var names by uppercasing the parameter names
  const customEnvVars: EnvironmentVar[] = Object.entries(params).map(([key, value]) => ({
    name: key.toUpperCase(),
    value: String(value),
  }));

  // Merge existing env vars with custom overrides
  const customVarNames = new Set(customEnvVars.map((v) => v.name));
  const existingEnvVars = container.env.filter((v) => !customVarNames.has(v.name));
  const mergedEnvVars = [...existingEnvVars, ...customEnvVars];

  // Step 3: Trigger the job
  const startJobUrl = `${baseUrl}/subscriptions/${config.azureSubscriptionId}/resourceGroups/${config.azureResourceGroup}/providers/Microsoft.App/jobs/${config.azureJobName}/start?api-version=${apiVersion}`;

  const requestBody = {
    containers: [
      {
        name: container.name,
        image: container.image,
        resources: container.resources,
        env: mergedEnvVars,
      },
    ],
  };

  const startResponse = await fetch(startJobUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(requestBody),
  });

  if (!startResponse.ok) {
    const errorText = await startResponse.text();
    throw new Error(`Failed to start job: ${startResponse.status} ${errorText}`);
  }

  const executionData = await startResponse.json();
  const executionResponse = validateData(executionData, JobExecutionResponseSchema);

  return {
    executionId: executionResponse.id,
    executionName: executionResponse.name,
  };
}
