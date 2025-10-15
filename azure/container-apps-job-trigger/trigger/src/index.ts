import {
  app,
  type HttpRequest,
  type HttpResponseInit,
  type InvocationContext,
} from '@azure/functions';
import { newApp } from './app';
import { createEnvConfig } from './config';
import { triggerContainerJob } from './trigger-job';
import { JobParamsSchema, type JobParams } from './types';
import { validateData } from './validation';
import { logAzureToSentry } from './sentry';

const MONITOR_SLUG = 'container-apps-job-trigger';

const main = logAzureToSentry(
  async (sentry, request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    context.log('🚀 Trigger Calculate Statistics Function invoked');
    const cfg = createEnvConfig();
    const app = await newApp(cfg, context);

    try {
      // Parse and validate request body
      const body = await request.json();
      app.logger.log(`📊 Request parameters: ${JSON.stringify(body)}`);

      let params: JobParams;
      try {
        params = validateData(body, JobParamsSchema);
      } catch (validationError) {
        app.logger.warn('⚠️ Invalid request body', validationError);
        return {
          status: 400,
          jsonBody: {
            success: false,
            error:
              validationError instanceof Error ? validationError.message : 'Invalid request body',
          },
        };
      }

      // Trigger the job
      app.logger.log('⚡ Triggering container job...');
      const result = await triggerContainerJob(app.config, params);

      app.logger.log(`✅ Job triggered successfully: ${result.executionName}`);

      return {
        status: 200,
        jsonBody: {
          success: true,
          message: 'Job triggered successfully',
          execution: {
            id: result.executionId,
            name: result.executionName,
          },
          parameters: params,
        },
      };
    } catch (error) {
      app.logger.error('❌ Error triggering job:', error);
      sentry?.captureException(error);

      return {
        status: 500,
        jsonBody: {
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error',
        },
      };
    }
  },
  MONITOR_SLUG,
);

// Register HTTP trigger
app.http('CalculateStatisticsTrigger', {
  methods: ['POST'],
  authLevel: 'function', // Requires function key for authentication
  handler: main,
});
