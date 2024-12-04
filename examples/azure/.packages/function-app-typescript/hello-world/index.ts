import type { AzureFunction, Context, HttpRequest } from '@azure/functions';

const handler: AzureFunction = async (context: Context, req: HttpRequest): Promise<void> => {
  const hello: string = 'Hello World from TypeScript!';
  context.log(hello);

  context.res = {
    statusCode: 200,
    body: hello,
  };
};

export default handler;
