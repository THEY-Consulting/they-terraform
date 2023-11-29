export const handler = async () => {
  try {
    const result = await fetch('http://ipv4.icanhazip.com/icanhazip.com');
    const resultText = await result.text();
    return {
      statusCode: 200,
      body: JSON.stringify({ msg: 'ok', outboundIp: resultText }),
      headers: {
        'Content-Type': 'application/json',
      },
    };
  } catch (err) {
    console.log(`error in handler: ${err}`);
    return {
      statusCode: 500,
      body: JSON.stringify({ msg: 'error' }),
      headers: {
        'Content-Type': 'application/json',
      },
    };
  }
};
