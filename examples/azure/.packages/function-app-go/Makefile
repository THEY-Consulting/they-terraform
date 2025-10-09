.PHONY: build build-local build-azure test deploy clean

# Build for local testing (native architecture)
build-local:
	CGO_ENABLED=0 go build -o handler handler.go

# Build for Azure deployment (Linux AMD64)
build-azure:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o handler handler.go

# Default build is for Azure
build: build-azure

# Test locally (builds for local architecture first)
test: build-local
	func start

# Deploy to Azure (builds for Linux AMD64 first)
deploy: build-azure
	cd ../../function_app_go && \
	terraform init && \
	terraform apply

clean:
	rm -f handler
	cd ../../function_app_go && terraform destroy

.DEFAULT_GOAL := build

