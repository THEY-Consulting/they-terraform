import { app, EventGridEvent, InvocationContext } from '@azure/functions';

const main = async (event: EventGridEvent, context: InvocationContext) => {
  context.log('Event:', event);
};

app.eventGrid('hello-world', {
  handler: main,
});
