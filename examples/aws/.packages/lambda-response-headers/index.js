const handler = async () => {
  console.log('Hello World!');

  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': true,
      'Custom-Header': 'Custom-Value',
    },
    body: 'Hello World!',
  };
};

exports.handler = handler;
