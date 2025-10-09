package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

func helloWorldHandler(w http.ResponseWriter, r *http.Request) {
	// Log incoming request for debugging in Azure
	log.Printf("Processing %s request to %s", r.Method, r.URL.Path)

	name := r.URL.Query().Get("name")
	if name == "" {
		name = "World"
	}

	message := fmt.Sprintf("Hello %s from Go!", name)
	log.Printf("Responding with: %s", message)

	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	io.WriteString(w, message)
}

func main() {
	// Configure logging to stdout (Azure captures stdout)
	log.SetOutput(os.Stdout)
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	customHandlerPort, exists := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT")
	if !exists {
		customHandlerPort = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/api/hello-world", helloWorldHandler)

	log.Printf("Go server listening on port %s", customHandlerPort)
	log.Fatal(http.ListenAndServe(":"+customHandlerPort, mux))
}

