import type { AzureFunction, Context } from '@azure/functions';

const handler: AzureFunction = async (context: Context, event): Promise<void> => {
  const trigger = event.data.url;
  context.log(`Hello World triggered by ${trigger}!`);
};

export default handler;
