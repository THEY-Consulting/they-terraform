const handler = async (context, req) => {
  context.log('Hello World!');

  context.res = {
    statusCode: 200,
    body: 'Hello World 👋',
  };
};

module.exports = handler;
