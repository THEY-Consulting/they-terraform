# They Terraform

Collection of modules to provide an easy way to create and deploy common infrastructure components.

##### Table of Contents

- [Use in your own project](#use-in-your-own-project)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
- [Modules](#modules)
  - [AWS](#aws)
    - [Lambda](#lambda)
    - [API Gateway (REST)](#api-gateway-rest)
    - [GitHub OpenID role](#github-openid-role)
    - [setup-tfstate](#setup-tfstate)
  - [Azure](#azure)
    - [Function app](#function-app)
- [Contributing](#contributing)
  - [Prerequisites](#prerequisites-1)
  - [Environment Variables](#environment-variables)
  - [Local Dev](#local-dev)
  - [Deployment](#deployment)

## Use in your own project

### Prerequisites

- [terraform](https://www.terraform.io/downloads.html) >= 1.5.0

Depending on the modules you want to use, you will need to have installed and configured:

- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### Usage

Include the modules you want to use in your terraform files:

```hcl
module "lambda_with_build" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda"

  description = "Test typescript lambda with build step"
  name        = "they-test-build"
  runtime     = "nodejs18.x"
  source_dir  = "packages/lambda-typescript"
}
```

and run `terraform init`.

For more examples see the [examples](./examples) directory.

## Modules

### AWS

The location of all resources is always determined by the `region` of your aws provider.

#### Lambda

```hcl
module "lambda" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda"

  name          = "they-test"
  description   = "Test lambda without build step"
  source_dir    = "packages/lambda-simple"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  architectures = ["arm64"]
  publish       = true
  memory_size   = 128
  timeout       = 3
  layers        = ["arn:aws:lambda:us-east-1:123456789012:layer:they-test-layer:1"]

  build = {
    enabled   = true
    command   = "yarn run build"
    build_dir = "dist"
  }

  is_bundle = false

  archive = {
    output_path = "dist/lambda.zip"
    excludes    = ["test"]
  }

  cloudwatch = {
    retention_in_days = 30
  }

  cron_trigger = {
    name        = "trigger-they-test-cron-lambda"
    description = "Test cron trigger"
    schedule    = "cron(0 9 ? * MON-FRI *)"
    input = jsonencode({
      "key1" : "value1",
      "key2" : "value2"
    })
  }

  bucket_trigger = {
    name          = "trigger-they-test-bucket-lambda"
    bucket        = "they-dev"
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "they-test-lambda/"
    filter_suffix = ".txt"
  }

  role_arn = "arn:aws:iam::123456789012:role/lambda-role"
  iam_policy = [{ // only used if role_arn is not set
    name = "custom-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["some:Action"]
        Resource = "some:resource:arn"
      }]
    })
  }]

  environment = {
    ENV_VAR_1 = "value1"
    ENV_VAR_2 = "value2"
  }

  vpc_config = {
    subnet_ids         = ["subnet-12345678"]
    security_group_ids = ["sg-12345678"]
  }

  tags = {
    createdBy = "terraform"
    environment = "dev"
  }
}
```

##### Inputs

| Variable                      | Type         | Description                                                                                                                        | Required | Default                    |
| ----------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------- |
| name                          | string       | Name of the lambda function                                                                                                        | yes      |                            |
| description                   | string       | Description of the lambda function                                                                                                 | yes      |                            |
| source_dir                    | string       | Directory containing the lambda function                                                                                           | yes      |                            |
| handler                       | string       | Function entrypoint                                                                                                                | no       | `"index.handler"`          |
| runtime                       | string       | The runtime that the function is executed with, e.g. 'nodejs18.x'.                                                                 | yes      |                            |
| architectures                 | list(string) | The instruction set architecture that the function supports                                                                        | no       | `["arm64"]`                |
| publish                       | bool         | Whether to publish creation/change as new Lambda Function Version                                                                  | no       | `true`                     |
| memory_size                   | number       | Amount of memory in MB your Lambda Function can use at runtime                                                                     | no       | `128`                      |
| timeout                       | number       | Amount of time your Lambda Function has to run in seconds                                                                          | no       | `3`                        |
| layers                        | list(string) | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function                                                 | no       | `[]`                       |
| build                         | object       | Build configurations                                                                                                               | no       | see sub fields             |
| build.enabled                 | bool         | Enable/Disable running build command                                                                                               | no       | `true`                     |
| build.command                 | string       | Build command to use                                                                                                               | no       | `"yarn run build"`         |
| build.build_dir               | string       | Directory where the compiled lambda files are generated, relative to the lambda source directory                                   | no       | `"dist"`                   |
| is_bundle                     | bool         | If true, node_modules and .yarn directories will be excluded from the archive.                                                     | no       | `false`                    |
| archive                       | object       | Configure archive file generation                                                                                                  | no       | see sub fields             |
| archive.output_path           | string       | Directory where the zipped file is generated, relative to the terraform file                                                       | no       | `"dist/{name}/lambda.zip"` |
| archive.excludes              | list(string) | List of strings with files that are excluded from the zip file                                                                     | no       | `[]`                       |
| cloudwatch                    | object       | CloudWatch configuration                                                                                                           | no       | see sub fields             |
| cloudwatch.retention_in_days  | number       | Retention for the CloudWatch log group                                                                                             | no       | `30`                       |
| cron_trigger                  | object       | Configuration to trigger the lambda through a cron schedule                                                                        | no       | `null`                     |
| cron_trigger.name             | string       | Name of the trigger                                                                                                                | (yes)    |                            |
| cron_trigger.description      | string       | Description of the trigger                                                                                                         | no       | `null`                     |
| cron_trigger.schedule         | string       | Schedule expression for the trigger                                                                                                | (yes)    |                            |
| cron_trigger.input            | string       | Valid JSON test passed to the trigger target                                                                                       | no       | `null`                     |
| bucket_trigger                | object       | Configuration to trigger the lambda through bucket events                                                                          | no       | `null`                     |
| bucket_trigger.name           | string       | Name of the trigger                                                                                                                | (yes)    |                            |
| bucket_trigger.bucket         | string       | Name of the bucket                                                                                                                 | (yes)    |                            |
| bucket_trigger.events         | list(string) | List of events that trigger the lambda                                                                                             | (yes)    |                            |
| bucket_trigger.filter_prefix  | string       | Trigger lambda only for files starting with this prefix                                                                            | no       | `null`                     |
| bucket_trigger.filter_suffix  | string       | Trigger lambda only for files starting with this suffix                                                                            | no       | `null`                     |
| role_arn                      | string       | ARN of the role used for executing the lambda function, if no role is given a role with cloudwatch access is created automatically | no       | `null`                     |
| iam_policy                    | list(object) | IAM policies to attach to the lambda role, only works if no custom `role_arn` is set                                               | no       | `[]`                       |
| iam_policy.\*.name            | string       | Name of the policy                                                                                                                 | (yes)    |                            |
| iam_policy.\*.policy          | string       | JSON encoded policy string                                                                                                         | (yes)    |                            |
| environment                   | map(string)  | Map of environment variables that are accessible from the function code during execution                                           | no       | `null`                     |
| vpc_config                    | object       | For network connectivity to AWS resources in a VPC                                                                                 | no       | `null`                     |
| vpc_config.security_group_ids | list(string) | List of security groups to connect the lambda with                                                                                 | (yes)    |                            |
| vpc_config.subnet_ids         | list(string) | List of subnets to attach to the lambda                                                                                            | (yes)    |                            |
| tags                          | map(string)  | Map of tags to assign to the Lambda Function and related resources                                                                 | no       | `{}`                       |

##### Outputs

| Output            | Type   | Description                                                      |
| ----------------- | ------ | ---------------------------------------------------------------- |
| arn               | string | The Amazon Resource Name (ARN) identifying your Lambda Function  |
| function_name     | string | The name of the Lambda Function                                  |
| invoke_arn        | string | The ARN to be used for invoking Lambda Function from API Gateway |
| build             | object | Build output                                                     |
| archive_file_path | string | Path to the generated archive file                               |

#### API Gateway (REST)

```hcl
module "api_gateway" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"

  name = "they-test-api-gateway"
  description = "Test API Gateway"
  stage_name = "dev"

  endpoints = [
    {
      path          = "hello-world"
      method        = "GET"
      function_arn  = "some:lambda:arn"
      function_name = "some_lambda_function_name"
    },
  ]

  api_key = {
    name = "they-test-api-key"
    value = "secret-test-api-gateway-key"
    description = "Test API Gateway Key"
    enabled = true
    usage_plan_name = "they-test-api-gateway-usage-plan"
    usage_plan_description = "Test API Gateway Usage Plan"
  }

  authorizer = {
    function_name         = "authorizer_lambda_function_name"
    invoke_arn            = "authorizer:lambda:arn"
    identity_source       = "method.request.header.Authorization"
    result_ttl_in_seconds = 0
    type                  = "REQUEST"
  }

  domain = {
    certificate_arn = "some:certificate:arn"
    zone_name       = "they-code.de."
    domain          = "they-test-lambda.they-code.de"
  }

  redeployment_trigger = "v1.0.0"

  tags = {
    createdBy = "terraform"
    environment = "dev"
  }
}
```

##### Inputs

| Variable                                  | Type         | Description                                                                                                                                                                                                 | Required | Default                                                   |
| ----------------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------------------------------------------- |
| name                                      | string       | Name of the api gateway                                                                                                                                                                                     | yes      |                                                           |
| description                               | string       | Description of the api gateway                                                                                                                                                                              | no       | `""`                                                      |
| stage_name                                | string       | Stage to use for the api gateway                                                                                                                                                                            | no       | `"dev"`                                                   |
| endpoints                                 | list(object) | The endpoints to create for the api gateway                                                                                                                                                                 | yes      |                                                           |
| endpoints.\*.path                         | string       | Path segment where the lambda function is reachable                                                                                                                                                         | yes      |                                                           |
| endpoints.\*.method                       | string       | HTTP Method (`GET`, `POST`, `PUT`, `DELETE`, `HEAD`, `OPTIONS`, `ANY`)                                                                                                                                      | yes      |                                                           |
| endpoints.\*.function_name                | string       | Name of the lambda function                                                                                                                                                                                 | yes      |                                                           |
| endpoints.\*.function_arn                 | string       | ARN of the lambda function                                                                                                                                                                                  | yes      |                                                           |
| endpoints.\*.authorization                | string       | Type of authorization used for the method (`NONE`, `CUSTOM`, `AWS_IAM`, `COGNITO_USER_POOLS`)                                                                                                               | no       | `"None"` or `"CUSTOM"` if `authorizer` is set             |
| endpoints.\*.authorizer_id                | string       | Authorizer id to be used when the authorization is `CUSTOM` or `COGNITO_USER_POOLS`                                                                                                                         | no       | `null` or authorizer id if `authorizer` is set            |
| endpoints.\*.api_key_required             | bool         | Specify if the method requires an API key                                                                                                                                                                   | no       | `true` if `api_key` is set, otherwise `false`             |
| api_key                                   | object       | Api key configuration to use for the api gateway                                                                                                                                                            | no       | `null`                                                    |
| api_key.name                              | string       | Specify if the method requires an API key                                                                                                                                                                   | no       | `"${var.name}-api-key"`                                   |
| api_key.value                             | string       | API key                                                                                                                                                                                                     | (yes)    |                                                           |
| api_key.description                       | string       | Description of the API key                                                                                                                                                                                  | no       | `null`                                                    |
| api_key.enabled                           | bool         | Enable/Disable the API key                                                                                                                                                                                  | no       | `true`                                                    |
| api_key.usage_plan_name                   | string       | Name of the internally created usage plan                                                                                                                                                                   | no       | `"${var.name}-usage-plan"`                                |
| api_key.usage_plan_description            | string       | Description of the internally created usage plan                                                                                                                                                            | no       | `null`                                                    |
| authorizer                                | object       | Authorizer configuration                                                                                                                                                                                    | no       | `null`                                                    |
| authorizer.function_name                  | string       | Name of the authorizer lambda function                                                                                                                                                                      | (yes)    |                                                           |
| authorizer.invoke_arn                     | string       | Invoke ARN of the authorizer lambda function                                                                                                                                                                | (yes)    |                                                           |
| authorizer.identity_source                | string       | Source of the identity in an incoming request                                                                                                                                                               | no       | `method.request.header.Authorization` (terraform default) |
| authorizer.type                           | string       | Type of the authorizer (`TOKEN`, `REQUEST`, `COGNITO_USER_POOLS`)                                                                                                                                           | no       | `TOKEN` (terraform default)                               |
| authorizer.result_ttl_in_seconds          | number       | TTL of cached authorizer results in seconds                                                                                                                                                                 | no       | `300` (terraform default)                                 |
| authorizer.identity_validation_expression | string       | The incoming token from the client is matched against this expression, and will proceed if the token matches                                                                                                | no       | `null`                                                    |
| domain                                    | object       | Domain configuration                                                                                                                                                                                        | no       | `null`                                                    |
| domain.certificate_arn                    | string       | ARN of the certificate that is used (required if s3_truststore_uri is not set)                                                                                                                              | no       |                                                           |
| domain.domain                             | string       | Domain                                                                                                                                                                                                      | (yes)    |                                                           |
| domain.s3_truststore_uri                  | string       | URI to truststore.pem used for verification of client certs (required if certificate_arn is not set)                                                                                                        | no       |                                                           |
| domain.zone_name                          | string       | Domain zone name                                                                                                                                                                                            | (yes)    |                                                           |
| redeployment_trigger                      | string       | A unique string to force a redeploy of the api gateway. If not set manually, the module will use the configurations for endpoints, api_key, and authorizer config to decide if a redeployment is necessary. | (yes)    |                                                           |
| tags                                      | map(string)  | Map of tags to assign to the Lambda Function and related resources                                                                                                                                          | no       | `{}`                                                      |

##### Outputs

| Output        | Type         | Description                       |
| ------------- | ------------ | --------------------------------- |
| invoke_url    | string       | The invoke URL of the api gateway |
| endpoint_urls | list(string) | List of all endpoint URLs         |

#### GitHub OpenID role

```hcl
module "github_action_role" {
  source = "github.com/THEY-Consulting/they-terraform//aws/openid/github"

  name = "they-test"
  repo = "THEY-Consulting/they-terraform"
  policies = [
    {
      name = "they-test-policy"
      policy = jsonencode({
        Version : "2012-10-17",
        Statement : [
          {
            Effect : "Allow",
            Action : [
              "s3:ListBucket",
            ],
            Resource : [
              "arn:aws:s3:::they-test-bucket",
            ]
          }
        ]
      })
    },
  ],
  s3StateBackend = true
}
```

##### Inputs

| Variable           | Type         | Description                                                                                                                                                                                              | Required | Default |
| ------------------ | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| name               | string       | Name of the role                                                                                                                                                                                         | yes      |         |
| repo               | string       | Repository that is authorized to assume this role                                                                                                                                                        | yes      |         |
| policies           | list(object) | List of additional inline policies to attach to the app                                                                                                                                                  | no       | `[]`    |
| policies.\*.name   | string       | Name of the inline policy                                                                                                                                                                                | yes      |         |
| policies.\*.policy | string       | Policy document as a JSON formatted string                                                                                                                                                               | yes      |         |
| s3StateBackend     | bool         | Set to true if a s3 state backend was setup with the setup-tfstate module (or uses the same naming scheme for the s3 bucket and dynamoDB table). This will set the required s3 and dynamoDB permissions. | no       | `true`  |

##### Outputs

| Output    | Type   | Description          |
| --------- | ------ | -------------------- |
| role_name | string | The name of the role |
| role_arn  | string | The ARN of the role  |

#### setup-tfstate

```hcl
module "setup_tfstate" {
  source = "github.com/THEY-Consulting/they-terraform//aws/setup-tfstate"

  name = "they-test"
}
```

##### Inputs

| Variable | Type   | Description                                                     | Required | Default |
| -------- | ------ | --------------------------------------------------------------- | -------- | ------- |
| name     | string | Name of the app, used for the s3 bucket and dynamoDB table name | yes      |         |

##### Outputs

| Output         | Type   | Description               |
| -------------- | ------ | ------------------------- |
| s3_bucket_arn  | string | The ARN of the s3 bucket  |
| s3_bucket_name | string | The name of the s3 bucket |

### Azure

#### Function app

```hcl
module "function_app_without_build" {
  source = "github.com/THEY-Consulting/they-terraform//azure/function-app"

  name                = "they-test"
  source_dir          = "packages/function-app"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  storage_account = {
    name             = "theydev"
    tier             = "Standard"
    replication_type = "RAGRS"
    min_tls_version  = "TLS1_2"
  }

  service_plan = {
    name     = "they-test"
    os_type  = "Windows"
    sku_name = "Y1"
  }

  insights = {
    enabled           = true
    sku               = "PerGB2018"
    retention_in_days = 30
  }

  environment = {
    ENV_VAR_1 = "value1"
    ENV_VAR_2 = "value2"
  }

  build = {
    enabled   = true
    command   = "yarn run build"
    build_dir = "dist"
  }

  is_bundle = false

  archive = {
    output_path = "dist/function-app.zip"
    excludes    = ["test"]
  }

  storage_trigger = {
    function_name                = "they-test"
    events                       = ["Microsoft.Storage.BlobCreated"]
    trigger_storage_account_name = "theydevtrigger"
    trigger_resource_group_name  = "they-dev"
    subject_filter = {
      subject_begins_with = "trigger/"
      subject_ends_with   = ".zip"
    }
    retry_policy = {
      event_time_to_live    = 360
      max_delivery_attempts = 1
    }
  }

  identity = {
    name = "they-test-identity"
  }

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}
```

##### Inputs

| Variable                                           | Type         | Description                                                                                      | Required | Default                                |
| -------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------ | -------- | -------------------------------------- |
| name                                               | string       | Name of the function app                                                                         | yes      |                                        |
| source_dir                                         | string       | Directory containing the function code                                                           | yes      |                                        |
| location                                           | string       | The Azure region where the resources should be created                                           | yes      |                                        |
| resource_group_name                                | string       | The name of the resource group in which to create the function app                               | yes      |                                        |
| storage_account_options                            | object       | Options for the to be created storage account. These only get applied if one will be created.    | no       | see sub fields                         |
| storage_account_options.is_hns_enabled             | bool         | Makes the storage account a "data lake storage" if enabled.                                      | no       | `false`                                |
| storage_account_options.tier                       | string       | Defines the Tier to use for this storage account. Valid options are Standard and Premium         | no       | `Standard`                             |
| storage_account_options.replication_type           | string       | Defines the type of replication to use for this storage account.                                 | no       | `RAGRS`                                |
| storage_account_options.min_tls_version            | string       | The minimum supported TLS version for the storage account.                                       | no       | `TLS1_2`                               |
| service_plan                                       | object       | The service plan                                                                                 | no       | see sub fields                         |
| service_plan.name                                  | string       | Name of an existing service plan, if this is `null` a new service plan will be created           | no       | `null`                                 |
| service_plan.os_type                               | string       | OS type of the service plan, ignored if `service_plan.name` is set                               | no       | `"Windows"`                            |
| service_plan.sku_name                              | string       | SKU name of the service plan, ignored if `service_plan.name` is set                              | no       | `"Y1"`                                 |
| insights                                           | object       | Application insights                                                                             | no       | see sub fields                         |
| insights.enabled                                   | bool         | Enable/Disable application insights                                                              | no       | `true`                                 |
| insights.sku                                       | string       | SKU for application insights                                                                     | no       | `"PerGB2018"`                          |
| insights.retention_in_days                         | number       | Retention for application insights in days                                                       | no       | `30`                                   |
| environment                                        | map(string)  | Map of environment variables that are accessible from the function code during execution         | no       | `{}`                                   |
| build                                              | object       | Build configuration                                                                              | no       | see sub fields                         |
| build.enabled                                      | bool         | Enable/Disable running build command                                                             | no       | `true`                                 |
| build.command                                      | string       | Build command to use                                                                             | no       | `"yarn run build"`                     |
| build.build_dir                                    | string       | Directory where the compiled lambda files are generated, relative to the lambda source directory | no       | `"dist"`                               |
| is_bundle                                          | bool         | If true, node_modules and .yarn directories will be excluded from the archive.                   | no       | `false`                                |
| archive                                            | object       | Archive configuration                                                                            | no       | see sub fields                         |
| archive.output_path                                | string       | Directory where the zipped file is generated, relative to the terraform file                     | no       | `"dist/{name}/azure-function-app.zip"` |
| archive.excludes                                   | list(string) | List of strings with files that are excluded from the zip file                                   | no       | `[]`                                   |
| storage_trigger                                    | object       | Trigger the azure function through storage event grid subscription                               | no       | see sub fields                         |
| storage_trigger.trigger_storage_account_name       | string       | Name of the storage account the trigger will be created on.                                      | (yes)    |                                        |
| storage_trigger.create_storage_account             | string       | Whether a new storage account will be created or an existing one will be used.                   | (yes)    |                                        |
| storage_trigger.function_name                      | string       | Name of the function that should be triggered                                                    | (yes)    |                                        |
| storage_trigger.events                             | list(string) | List of event names that should trigger the function                                             | (yes)    |                                        |
| storage_trigger.trigger_resource_group_name        | string       | The resource group the storage account is in. Defaults to the resource group of the function app.| (no)     |                                        |
| storage_trigger.subject_filter                     | object       | filter events for the event subscription                                                         | no       | `null`                                 |
| storage_trigger.subject_filter.subject_begins_with | string       | A string to filter events for an event subscription based on a resource path prefix              | no       | `null`                                 |
| storage_trigger.subject_filter.subject_ends_with   | string       | A string to filter events for an event subscription based on a resource path suffix              | no       | `null`                                 |
| storage_trigger.retry_policy                       | object       | Retry policy                                                                                     | no       | see sub fields                         |
| storage_trigger.retry_policy.event_time_to_live    | number       | Specifies the time to live (in minutes) for events                                               | no       | `360`                                  |
| storage_trigger.retry_policy.max_delivery_attempts | number       | Specifies the maximum number of delivery retry attempts for events                               | no       | `1`                                    |
| identity                                           | object       | Identity to use                                                                                  | no       | `null`                                 |
| identity.name                                      | string       | Name of the identity                                                                             | (yes)    |                                        |
| tags                                               | map(string)  | Map of tags to assign to the function app and related resources                                  | no       | `{}`                                   |

##### Outputs

| Output            | Type   | Description                        |
| ----------------- | ------ | ---------------------------------- |
| id                | string | The ID of the Function App         |
| build             | string | Build output                       |
| archive_file_path | string | Path to the generated archive file |
| endpoint_url      | string | Endpoint URL                       |

## Contributing

### Prerequisites

- [terraform](https://www.terraform.io/downloads.html) version 1.5.0
- [tfenv](https://github.com/tfutils/tfenv) optional, recommended
- [nodejs](https://nodejs.org/en) version 18.X
- [yarn](https://classic.yarnpkg.com/lang/en/docs/) `npm i -g yarn`
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [direnv](https://direnv.net/)

### Environment Variables

- set up your environment variables (create and put them in `.envrc` in the project's root dir):

```txt
export AWS_PROFILE=nameOfProfile
export AZURE_TENANT_ID=<see https://portal.azure.com/#settings/directory for the correct Directory ID>
export TF_VAR_tenant_id=$AZURE_TENANT_ID

```

- remember to add the aws profile info to `~/.aws/config`
- and the key and secret for said profile to `~/.aws/credentials`

### Local Dev

Install dependencies:

```bash
cd examples/aws/packages
yarn install

cd examples/azure/packages
yarn install
```

### Deployment

Currently, we only use a single workspace within each cloud provider.
To deploy each example (temporarily) use:

```bash
cd examples/aws/<example>
terraform apply

cd examples/azure/<example>
terraform apply
```

When you are done testing, please destroy the resources with `terraform destroy`.

_examples/setup-tfstate_ can be deployed the same way, but it is a bit more complicated to clean up.
`terraform destroy` can not remove the s3 bucket (due to `prevent_destroy = true`).
Therefore, you need to delete the bucket manually.
After that you can remove the remaining resources with `terraform destroy`.
Keep in mind that after destroying a bucket it can take up to 24 hours until the name is available again.
