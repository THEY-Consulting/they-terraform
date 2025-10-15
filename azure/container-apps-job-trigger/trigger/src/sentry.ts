import { type InvocationContext } from '@azure/functions';
import * as Sentry from '@sentry/node';

export type AzureSentry = typeof Sentry;

export type AzureHandler<Event, Return> = (
  event: Event,
  context: InvocationContext,
) => Promise<Return>;

export type AzureSentryFn<Event, Return> = (
  sentry: AzureSentry,
  ...args: Parameters<AzureHandler<Event, Return>>
) => ReturnType<AzureHandler<Event, Return>>;

export const logAzureToSentry = <Event, Return>(
  handler: AzureSentryFn<Event, Return>,
  monitorSlug?: string,
): AzureHandler<Event, Return> => {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    tracesSampleRate: 1,
    environment: process.env.SENTRY_ENV || 'dev',
    maxValueLength: 100000, // Set to a big value so Sentry will not truncate values
    release: process.env.VERSION || 'n.a.',
  });

  Sentry.setTag('version', process.env.VERSION || 'n.a.');
  Sentry.setTag('package', monitorSlug ?? 'n.a.');
  Sentry.setTag('cloud', 'azure');

  return async (event, context) => {
    // Configure the current scope for this invocation so all Sentry calls
    // (including those caught locally in handlers) get the transaction and context
    const scope = Sentry.getCurrentScope();
    scope.addEventProcessor((event) => {
      event.transaction = context.functionName;
      return event;
    });
    scope.setContext('InvocationContext', {
      invocationId: context.invocationId,
      functionName: context.functionName,
    });

    const checkInId = monitorSlug
      ? Sentry.captureCheckIn({ monitorSlug, status: 'in_progress' })
      : null;
    context.log(`🔵 CheckIn ${monitorSlug} (${checkInId} / ${process.env.SENTRY_ENV})`);

    try {
      const result = await handler(Sentry, event, context);
      if (checkInId && monitorSlug) {
        Sentry.captureCheckIn({ checkInId, monitorSlug, status: 'ok' });
        context.log(`🟢 CheckIn ok ${monitorSlug} (${checkInId} / ${process.env.SENTRY_ENV})`);
      }

      return result;
    } catch (error) {
      if (checkInId && monitorSlug) {
        Sentry.captureCheckIn({ checkInId, monitorSlug, status: 'error' });
        context.log(`🔴 CheckIn error ${monitorSlug} (${checkInId} / ${process.env.SENTRY_ENV})`);
      }

      Sentry.captureException(error);
      await Sentry.flush(2000);
      throw error;
    }
  };
};
