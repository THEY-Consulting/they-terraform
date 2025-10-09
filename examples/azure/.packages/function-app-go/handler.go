package main

import (
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
)

func helloWorldHandler(w http.ResponseWriter, r *http.Request) {
	// Log incoming request for debugging in Azure
	slog.Info("Processing request",
		"method", r.Method,
		"path", r.URL.Path,
		"query", r.URL.RawQuery)

	name := r.URL.Query().Get("name")
	if name == "" {
		name = "World"
	}

	message := fmt.Sprintf("Hello %s from Go!", name)
	slog.Info("Responding with message", "message", message, "name", name)

	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	io.WriteString(w, message)
}

func main() {
	// Configure structured JSON logging to stdout (Azure captures stdout)
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	customHandlerPort, exists := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT")
	if !exists {
		customHandlerPort = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/api/hello-world", helloWorldHandler)

	slog.Info("Go server starting", "port", customHandlerPort)
	if err := http.ListenAndServe(":"+customHandlerPort, mux); err != nil {
		slog.Error("Server failed", "error", err)
		os.Exit(1)
	}
}
