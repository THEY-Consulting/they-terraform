package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

type Event struct {
	Name string `json:"name"`
}

type Response struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}

func HandleRequest(ctx context.Context, event *Event) (Response, error) {
	if event == nil {
		return Response{}, fmt.Errorf("received nil event")
	}

	message := fmt.Sprintf("Hello %s!", event.Name)
	return Response{Status: "ok", Message: message}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
