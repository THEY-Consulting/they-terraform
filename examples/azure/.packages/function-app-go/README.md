# Azure Function App - Go Example

This example demonstrates how to deploy a Go-based Azure Function using custom handlers.

## Language Agnostic

While this example uses **Go**, Azure Functions custom handlers work with **any language** that can:
- Compile to a native binary
- Listen on an HTTP port
- Handle HTTP requests

You could use **Rust**, **C++**, **Zig**, **Nim**, or any other compiled language. The Terraform module and Azure Functions runtime don't care about the source language - they only interact with the compiled binary and the configuration files (`host.json`, `function.json`).

## Prerequisites

- [Go](https://go.dev/dl/) (version 1.21 or later)
- [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) (version 4.x)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (for deployment)

## Important Notes

### Architecture Requirements

**Azure App Service only supports x86-64 (AMD64) architecture.** This means:
- All Go binaries must be compiled with `GOARCH=amd64`
- ARM64/aarch64 is **not supported** by Azure App Service
- If you're on an Apple Silicon Mac (M1/M2/M3/M4), you must cross-compile for AMD64

### Build Requirements

Go functions require pre-compilation before deployment:
- The binary must be named `handler` (no `.exe` extension)
- It must be compiled for Linux x64: `GOOS=linux GOARCH=amd64`
- Use `CGO_ENABLED=0` for static linking (no runtime dependencies)
- **DO NOT commit the binary to git** - build it locally or via CI/CD

## Quick Start

### Option 1: Using Make (Recommended)

```bash
# Build for local testing (native architecture)
make build-local

# Test locally
make test

# Build for Azure deployment (Linux AMD64)
make build-azure

# Deploy to Azure
make deploy

# Clean up
make clean
```

**Note:**
- `make build-local` builds for your native architecture (for local testing with `func start`)
- `make build-azure` or `make build` builds for Linux AMD64 (for Azure deployment)
- `make test` automatically builds for local architecture first
- `make deploy` automatically builds for Azure architecture first

### Option 2: Manual Build

```bash
# For local testing (native architecture)
CGO_ENABLED=0 go build -o handler handler.go
func start

# For Azure deployment (Linux AMD64)
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o handler handler.go

# Deploy with Terraform
cd ../../function_app_go
terraform init
terraform apply
```

## Testing Locally

After building, you can test the function locally:

```bash
# Start the function locally
func start

# In another terminal, test the endpoint
curl "http://localhost:7071/api/hello-world?name=Test"
```

Expected response: `Hello Test from Go!`

## Project Structure

```
function-app-go/
├── handler.go           # Main Go application
├── go.mod              # Go module definition
├── host.json           # Azure Functions host configuration
├── hello-world/        # Function definition
│   └── function.json   # Function bindings
├── Makefile            # Build automation
├── .gitignore          # Git ignore rules (excludes binary)
├── .funcignore         # Function deployment ignore rules
└── README.md           # This file
```

## How It Works

### Custom Handlers

Go support in Azure Functions is implemented using [Custom Handlers](https://learn.microsoft.com/en-us/azure/azure-functions/functions-custom-handlers):

1. **host.json** configures Azure to use a custom handler pointing to the `handler` binary
2. **handler.go** implements a standard Go HTTP server
3. Azure Functions host forwards HTTP requests to your Go server
4. The route `/api/hello-world` must match the function folder name

### Key Configuration

**host.json:**
- `extensionBundle`: Version `[4.*, 5.0.0)` (current recommended version)
- `defaultExecutablePath`: Points to the compiled binary (`handler`)
- `enableForwardingHttpRequest`: Simplifies HTTP handling

**handler.go:**
- Listens on port from `FUNCTIONS_CUSTOMHANDLER_PORT` environment variable
- Implements standard Go HTTP handlers
- Logs to stdout for Azure Application Insights

## Deployment

The Terraform configuration in `examples/azure/function_app_go/` deploys this function with:

```hcl
runtime = {
  name    = "go"
  version = "1.25"  # Informational only
  os      = "linux" # Required for Go
}

build = {
  enabled = false  # Go must be pre-compiled
}
```

**Important:** Always build the binary before running `terraform apply`!

## Troubleshooting

### Error: "Failed to start custom handler"

**Cause:** Binary not found or not executable.

**Solution:**
1. Verify `handler` binary exists: `ls -la handler`
2. Rebuild with correct flags: `CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o handler handler.go`

### Error: "exec format error"

**Cause:** Binary compiled for wrong architecture (e.g., ARM64 instead of AMD64).

**Solution:** Always use `GOARCH=amd64`:
```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o handler handler.go
```

### Error: HTTP 404 on function endpoint

**Cause:** Route mismatch between handler and function folder name.

**Solution:** Ensure the route in `handler.go` matches the folder name:
- Folder: `hello-world/`
- Route: `mux.HandleFunc("/api/hello-world", ...)`

### Function times out or doesn't respond

**Cause:** Handler not listening on correct port.

**Solution:** Verify the handler reads `FUNCTIONS_CUSTOMHANDLER_PORT`:
```go
customHandlerPort, exists := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT")
if !exists {
    customHandlerPort = "8080"
}
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
- name: Setup Go
  uses: actions/setup-go@v5
  with:
    go-version: '1.25'

- name: Build Go Function
  run: |
    cd examples/azure/.packages/function-app-go
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o handler handler.go

- name: Deploy with Terraform
  run: |
    cd examples/azure/function_app_go
    terraform init
    terraform apply -auto-approve
```

## Using Other Trigger Types

Go custom handlers support **all Azure Functions trigger types**, not just HTTP triggers. The extension bundle configured in `host.json` provides access to all trigger and binding types.

### Supported Triggers

- ✅ HTTP triggers (this example)
- ✅ Timer triggers (scheduled jobs)
- ✅ Blob Storage triggers
- ✅ Queue triggers
- ✅ Event Grid triggers
- ✅ Service Bus triggers
- ✅ Cosmos DB triggers
- ✅ Event Hub triggers

### Example: Timer Trigger

**Create `scheduled-job/function.json`:**
```json
{
  "bindings": [
    {
      "name": "myTimer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 */5 * * * *"
    }
  ]
}
```

**Add handler in `handler.go`:**
```go
mux.HandleFunc("/scheduled-job", func(w http.ResponseWriter, r *http.Request) {
    slog.Info("Timer triggered job started")

    // Your scheduled logic here

    w.WriteHeader(http.StatusOK)
})
```

### Example: Blob Storage Trigger

**Create `process-blob/function.json`:**
```json
{
  "bindings": [
    {
      "name": "myBlob",
      "type": "blobTrigger",
      "direction": "in",
      "path": "uploads/{name}",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

**Add handler in `handler.go`:**
```go
type BlobTriggerPayload struct {
    Data struct {
        BlobURL string `json:"blobUrl"`
    } `json:"Data"`
}

mux.HandleFunc("/process-blob", func(w http.ResponseWriter, r *http.Request) {
    var payload BlobTriggerPayload
    json.NewDecoder(r.Body).Decode(&payload)

    slog.Info("Processing blob", "url", payload.Data.BlobURL)

    // Process the blob

    w.WriteHeader(http.StatusOK)
})
```

### Example: Queue Trigger

**Create `process-queue/function.json`:**
```json
{
  "bindings": [
    {
      "name": "myQueueItem",
      "type": "queueTrigger",
      "direction": "in",
      "queueName": "myqueue",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

**Add handler in `handler.go`:**
```go
type QueueMessage struct {
    Data string `json:"Data"`
}

mux.HandleFunc("/process-queue", func(w http.ResponseWriter, r *http.Request) {
    var msg QueueMessage
    json.NewDecoder(r.Body).Decode(&msg)

    slog.Info("Processing queue message", "data", msg.Data)

    // Process the message

    w.WriteHeader(http.StatusOK)
})
```

### Important Notes for Non-HTTP Triggers

1. **Custom Handler Payload Format**: For non-HTTP triggers, Azure sends data in a specific JSON format. You may want to set `enableForwardingHttpRequest: false` in `host.json` for more control.

2. **Connection Strings**: Add required connection strings to your Terraform configuration:
   ```hcl
   environment = {
     AzureWebJobsStorage = "your-storage-connection-string"
   }
   ```

3. **Route Naming**: The route in your Go handler must match the function folder name:
   - Folder: `process-blob/` → Route: `/process-blob`
   - Folder: `scheduled-job/` → Route: `/scheduled-job`

4. **Extension Bundle**: Already configured in `host.json` with version `[4.*, 5.0.0)`, which provides all trigger types.

## References

- [Azure Functions Custom Handlers](https://learn.microsoft.com/en-us/azure/azure-functions/functions-custom-handlers)
- [Azure Functions Triggers and Bindings](https://learn.microsoft.com/en-us/azure/azure-functions/functions-triggers-bindings)
- [Create a Go function using Visual Studio Code](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-other)
- [Azure App Service Architecture Support](https://learn.microsoft.com/en-us/azure/app-service/tutorial-custom-container)

