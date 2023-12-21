import { APIGatewayRequestAuthorizerEvent, APIGatewayAuthorizerResult } from 'aws-lambda';

const key = process.env.AUTH_HASH;

export const handler = async ({
  headers,
  methodArn,
}: APIGatewayRequestAuthorizerEvent): Promise<APIGatewayAuthorizerResult> => {
  const valid = checkToken(headers.Authorization || '');

  return {
    principalId: 'basic-auth-user',
    policyDocument: {
      Version: '2012-10-17',
      Statement: [
        {
          Action: 'execute-api:Invoke',
          Effect: valid ? 'Allow' : 'Deny',
          Resource: methodArn,
        },
      ],
    },
  };
};

const checkToken = (token: string) => {
  return token === `Basic ${key}`;
};
