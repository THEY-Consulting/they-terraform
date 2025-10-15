import { app, type HttpRequest, type HttpResponseInit, type InvocationContext } from '@azure/functions';
import { newApp } from './app';
import { createEnvConfig } from './config';
import { triggerContainerJob } from './trigger-job';
import { JobParams } from './types';

const main = async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
  context.log('🚀 Trigger Calculate Statistics Function invoked');
  const cfg = createEnvConfig();
  const app = await newApp(cfg, context);

  try {
    // Parse and validate request body
    const jobParams = await request.json() as JobParams;
    app.logger.log(`📊 Request parameters: ${JSON.stringify(jobParams)}`);

    // Trigger the job
    app.logger.log('⚡ Triggering container job...');
    const execution = await triggerContainerJob(app.config, jobParams);

    app.logger.log(`✅ Job triggered successfully: ${execution.name}`);

    return {
      status: 200,
      jsonBody: {
        success: true,
        message: 'Job triggered successfully',
        execution,
        parameters: jobParams,
      },
    };
  } catch (error) {
    app.logger.error('❌ Error triggering job:', error);

    return {
      status: 500,
      jsonBody: {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
    };
  }
};

// Register HTTP trigger
app.http('CalculateStatisticsTrigger', {
  methods: ['POST'],
  authLevel: 'function', // Requires function key for authentication
  handler: main,
});
