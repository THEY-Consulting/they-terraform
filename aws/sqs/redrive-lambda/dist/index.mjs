import {
  SendMessageCommand,
  SQSClient,
  ReceiveMessageCommand,
  DeleteMessageCommand,
} from "@aws-sdk/client-sqs";

export const handler = async (_event) => {
  const sqs = new SQSClient();
  const sourceQueueUrl = process.env.SOURCE_QUEUE_URL;
  const targetQueueUrl = process.env.TARGET_QUEUE_URL;

  console.log(`Starting redrive from ${sourceQueueUrl} to ${targetQueueUrl}`);

  let processedCount = 0;

  while (true) {
    const response = await sqs.send(
      new ReceiveMessageCommand({
        QueueUrl: sourceQueueUrl,
        MaxNumberOfMessages: 10,
        WaitTimeSeconds: 10,
        MessageAttributeNames: ["All"],
        MessageSystemAttributeNames: ["All"],
      }),
    );

    if (response.Messages == undefined || response.Messages.length === 0) {
      console.log("No more messages to process");
      break;
    }
    console.log(
      `Got ${response.Messages.length} message${response.Messages.length > 1 ? "s" : ""}`,
    );

    for (const msg of response.Messages) {
      await sqs.send(
        new SendMessageCommand({
          QueueUrl: targetQueueUrl,
          MessageBody: msg.Body,
          MessageAttributes: msg.MessageAttributes,
        }),
      );
      await sqs.send(
        new DeleteMessageCommand({
          QueueUrl: sourceQueueUrl,
          ReceiptHandle: msg.ReceiptHandle,
        }),
      );
      console.log(
        `Redrove message: ${JSON.stringify(msg)} from ${sourceQueueUrl} to ${targetQueueUrl}`,
      );
      processedCount++;
    }
  }

  console.log(`Successfully redrove ${processedCount} messages`);
};
