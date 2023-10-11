import type { AzureFunction, Context, HttpRequest } from '@azure/functions';
import { helloWorldMessage } from './message';

const handler: AzureFunction = async (context: Context, req: HttpRequest): Promise<void> => {
  context.log(helloWorldMessage);

  context.res = {
    statusCode: 200,
    body: helloWorldMessage,
  };
};

export default handler;
