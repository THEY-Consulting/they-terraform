package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/lambdacontext"
)

// The Lambda function will parse received events into this
// data structure.
type Event struct {
	Name string `json:"name"`
}

type Response struct {
	Status    string `json:"status"`
	Message   string `json:"message"`
	RequestId string `json:"request_id"`
}

func HandleRequest(ctx context.Context, event *Event) (Response, error) {
	if event == nil {
		return Response{}, fmt.Errorf("received nil event")
	}

	lctx, ok := lambdacontext.FromContext(ctx)
	if !ok {
		errorMessage := "could not retrieve lambda's context"
		return Response{Status: "error", Message: errorMessage}, fmt.Errorf("%s", errorMessage)
	}

	// Logs directly to CloudWatch.
	log.Printf("Lambda function was invoked. RequestID: %s", lctx.AwsRequestID)

	message := fmt.Sprintf("Hello %s!", event.Name)
	return Response{Status: "ok", Message: message, RequestId: lctx.AwsRequestID}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
