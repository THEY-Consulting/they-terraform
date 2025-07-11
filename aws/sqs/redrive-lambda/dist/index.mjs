import {
  SQSClient,
  ReceiveMessageCommand,
  DeleteMessageCommand,
} from "@aws-sdk/client-sqs";
import { SendMessageCommand } from "@aws-sdk/client-sqs";

const sqs = new SQSClient();

export const handler = async (_event) => {
  const sourceQueueUrl = process.env.SOURCE_QUEUE_URL;
  const targetQueueUrl = process.env.TARGET_QUEUE_URL;

  console.log(`Starting redrive from ${sourceQueueUrl} to ${targetQueueUrl}`);

  let processedCount = 0;

  try {
    while (true) {
      const receiveParams = {
        QueueUrl: sourceQueueUrl,
        MaxNumberOfMessages: 10,
        WaitTimeSeconds: 1,
      };

      const receiveResult = await sqs.send(
        new ReceiveMessageCommand(receiveParams),
      );

      if (!receiveResult.Messages || receiveResult.Messages.length === 0) {
        console.log("No more messages to process");
        break;
      }

      for (const message of receiveResult.Messages) {
        const sendParams = {
          QueueUrl: targetQueueUrl,
          MessageBody: message.Body,
          MessageAttributes: message.MessageAttributes,
        };

        await sqs.send(new SendMessageCommand(sendParams));

        const deleteParams = {
          QueueUrl: sourceQueueUrl,
          ReceiptHandle: message.ReceiptHandle,
        };

        await sqs.send(new DeleteMessageCommand(deleteParams));
        console.log(
          `Redrove message: ${msgString(message)} from ${sourceQueueUrl} to ${targetQueueUrl}`,
        );
        processedCount++;
      }
    }

    console.log(`Successfully redrove ${processedCount} messages`);
    return { statusCode: 200, body: JSON.stringify({ processedCount }) };
  } catch (error) {
    console.error("Error redriving messages:", error);
    throw error;
  }
};

const msgString = (msg) => {
  try {
    return JSON.stringify(msg);
  } catch (err) {
    return msg;
  }
};
