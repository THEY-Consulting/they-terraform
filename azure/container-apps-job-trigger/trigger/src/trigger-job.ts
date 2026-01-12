import { DefaultAzureCredential } from '@azure/identity';
import { type Config } from './config';
import { Api, Container, ExecutionResponse, JobConfigResponse, JobParams } from './types';

const getAccessToken = async () => {
  const credential = new DefaultAzureCredential();
  const tokenResponse = await credential.getToken('https://management.azure.com/.default');
  return tokenResponse.token;
};

const getJobContainers = async (config: Config, api: Api) => {
  const jobConfigUrl = `${api.baseUrl}${config.azureJobResourceId}?api-version=${api.apiVersion}`;

  const configResponse = await fetch(jobConfigUrl, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${api.accessToken}`,
      'Content-Type': 'application/json',
    },
  });

  if (!configResponse.ok) {
    const errorText = await configResponse.text();
    throw new Error(`Failed to fetch job configuration: ${configResponse.status} ${errorText}`);
  }

  const jobConfig = await configResponse.json() as JobConfigResponse;
  if (!jobConfig.properties.template.containers.length) {
    throw new Error('No container found in job configuration');
  }

  return jobConfig.properties.template.containers;
};

const getMergedContainerConfigs = (containers: Container[], overrides: JobParams) => {
  return containers.map((container) => {
    const remaining = container.env.filter((v) => !overrides[v.name]);
    const newVars = Object.entries(overrides).map(([name, value]) => ({ name, value }));

    return {
      name: container.name,
      image: container.image,
      resources: container.resources,
      env: [...remaining, ...newVars],
    };
  });
};

const executeContainerJob = async (containers: Container[], config: Config, api: Api) => {
  const startJobUrl = `${api.baseUrl}${config.azureJobResourceId}/start?api-version=${api.apiVersion}`;
  const requestBody = { containers };
  const startResponse = await fetch(startJobUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${api.accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(requestBody),
  });

  if (!startResponse.ok) {
    const errorText = await startResponse.text();
    throw new Error(`Failed to start job: ${startResponse.status} ${errorText}`);
  }

  const { id, name } = await startResponse.json() as ExecutionResponse;

  return { id, name };
};

/**
 * Triggers an Azure Container Apps Job with custom parameters
 */
export async function triggerContainerJob(
  config: Config,
  params: JobParams,
) {
  const api = {
    baseUrl: 'https://management.azure.com',
    apiVersion: '2024-03-01',
    accessToken: await getAccessToken(),
  };

  const containers = await getJobContainers(config, api);
  const mergedContainers = getMergedContainerConfigs(containers, params);
  return await executeContainerJob(mergedContainers, config, api);
}
