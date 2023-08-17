import type { HttpRequest, InvocationContext } from '@azure/functions';
import { app } from '@azure/functions';

app.http('helloWorld', {
  methods: ['GET'],
  handler: async (request: HttpRequest, context: InvocationContext) => {
    context.log('Http function processed request');
    return { body: `Hello v4!` };
  },
});
