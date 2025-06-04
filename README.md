# They Terraform

Collection of modules to provide an easy way to create and deploy common infrastructure components.

##### Table of Contents

- [Use in your own project](#use-in-your-own-project)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
- [Modules](#modules)
  - [AWS](#aws)
    - [RDS postgres database](#rds-postgres-database)
    - [Lambda](#lambda)
    - [SNS](#sns)
    - [SQS](#sqs)
    - [API Gateway (REST)](#api-gateway-rest)
    - [S3 Bucket](#s3-bucket)
    - [S3 Log Bucket Policy](#s3-log-bucket-policy)
    - [Auto Scaling group](#auto-scaling-group)
    - [CloudFront Distribution](#cloudfront-distribution)
    - [Azure OpenID role](#azure-openid-role)
    - [GitHub OpenID role](#github-openid-role)
    - [setup-tfstate](#setup-tfstate)
    - [Outbound proxy VPC](#outbound-proxy-vpc)
  - [Azure](#azure)
    - [Function app](#function-app)
    - [MSSQL Database](#mssql-database)
    - [VM](#vm)
    - [Container Instances](#container-instances)
    - [Datadog Diagnostics](#datadog-diagnostics)
    - [Frontdoor](#front-door)
    - [Container Registry](#container-registry)
- [Contributing](#contributing)
  - [Prerequisites](#prerequisites-1)
  - [Environment Variables](#environment-variables)
  - [Local Dev](#local-dev)
  - [Deployment](#deployment)

## Use in your own project

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.6.4

Depending on the modules that you want to use, you need to have installed and configured the following command line tools:

- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### Usage

Include the modules that you want to use in your terraform files:

```hcl
module "lambda_with_build" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda"

  description = "Test typescript lambda with build step"
  name        = "they-test-build"
  runtime     = "nodejs20.x"
  source_dir  = "packages/lambda-typescript"
}
```

and run `terraform init`.

For more examples see the [examples](./examples) directory.

If you want to use a specific version of the module, you can specify the version, commit or branch name (urlencoded) in the source url:

```hcl
module "lambda_with_build" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda?ref=v0.1.0"
}

module "lambda_with_build" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda?ref=ee423515"
}
```

See [the official terraform documentation](https://developer.hashicorp.com/terraform/language/modules/sources#selecting-a-revision) for more details on using a specific version.

Specific providers can be set for modules by using the `providers` argument:

```hcl
provider "aws" {
  region = "eu-west-1"
  alias  = "specific"
}

module "lambda_with_specific_provider" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda"

  providers = {
    aws = aws.specific
  }
}
```

## Modules

### AWS

The location of all resources is always determined by the `region` of your aws `provider`.

#### RDS postgres database

```hcl
module "rds_postgres_database" {
  source = "github.com/THEY-Consulting/they-terraform//aws/database/rds"

  db_identifier  = "dev-they-terraform-products" # Unique name used to identify your database in the aws console
  engine         = "postgres"
  engine_version = "15.5"

  user_name      = "psql"
  password       = sensitive("Passw0rd123")

  allocated_storage     = 5
  max_allocated_storage = 30

  instance_class        = "db.t4g.micro"
  multi_az              = false
  storage_type          = "gp2"

  backup_retention_period = 14
  backup_window           = "03:00-04:00"

  publicly_accessible = true
  apply_immediately   = true

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}
```

##### Inputs

| Variable                | Type        | Description                                                                                      | Required | Default          |
| ----------------------- | ----------- | ------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| db_identifier           | string      | Unique name used to identify your database in the aws console                                    | yes      |                  |
| engine                  | string      | Engine of the database                                                                           | no       | `"postgres"`     |
| engine_version          | string      | Database's engine version                                                                        | no       | `"15.5"`         |
| user_name               | string      | Main username for the database                                                                   | no       | `"psql"`         |
| password                | string      | Password of the main username for the database                                                   | yes      |                  |
| allocated_storage       | number      | Allocated storage for the DB in GBs                                                              | no       | `5`              |
| max_allocated_storage   | number      | Upper limit to which the RDS can automatically scale the storage of the db instance              | no       | `30`             |
| instance_class          | string      | Instance class of database                                                                       | no       | `"db.t4g.micro"` |
| multi_az                | bool        | Specifies whether the RDS is multi-AZ                                                            | no       | `false`          |
| storage_type            | string      | Database's storage type                                                                          | no       | `"gp2"`          |
| backup_retention_period | number      | The number of days to retain backups for                                                         | no       | `14`             |
| backup_window           | string      | Daily time range for when backup creation is run                                                 | no       | `03:00-04:00`    |
| publicly_accessible     | bool        | Enable/Disable depending on whether db needs to be publicly accessible                           | no       | `true`           |
| apply_immediately       | bool        | Specifies whether db modifications are applied immediately or during the next maintenance window | no       | `true`           |
| tags                    | map(string) | Map of tags to assign to the RDS instance and related resources                                  | no       | `{}`             |
| vpc_cidr_block          | string      | CIDR block for the VPC                                                                           | no       | `"10.0.0.0/24"`  |
| skip_final_snapshot     | bool        | Creates final DB snapshot when deleting the database. If true, no snapshot is created            | no       | `false`          |

##### Outputs

| Output               | Type   | Description                                                                  |
| -------------------- | ------ | ---------------------------------------------------------------------------- |
| db_connection_string | string | Connection String that can be used to connect to created/updated db instance |
| hostname             | string | Hostname of the RDS instance                                                 |
| port                 | string | Port on which database is listening on                                       |
| engine               | object | Database engine                                                              |
| db_username          | string | Main username for the database                                               |

#### Lambda

```hcl
module "lambda" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda"

  name          = "they-test"
  description   = "Test lambda without build step"
  source_dir    = "packages/lambda-simple"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
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

  mount_efs = aws_efs_access_point.main.arn

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
| runtime                       | string       | The runtime that the function is executed with, e.g. 'nodejs20.x'.                                                                 | yes      |                            |
| architectures                 | list(string) | The instruction set architecture that the function supports                                                                        | no       | `["arm64"]`                |
| publish                       | bool         | Whether to publish creation/change as new Lambda Function Version                                                                  | no       | `true`                     |
| memory_size                   | number       | Amount of memory in MB your Lambda Function can use at runtime                                                                     | no       | `128`                      |
| timeout                       | number       | Amount of time your Lambda Function has to run in seconds                                                                          | no       | `3`                        |
| layers                        | list(string) | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function                                                 | no       | `[]`                       |
| build                         | object       | Build configurations                                                                                                               | no       | see sub fields             |
| build.enabled                 | bool         | Enable/Disable running build command                                                                                               | no       | `true`                     |
| build.command                 | string       | Build command to use                                                                                                               | no       | `"yarn run build"`         |
| build.build_dir               | string       | Directory where the compiled lambda files are generated, relative to the lambda source directory                                   | no       | `"dist"`                   |
| is_bundle                     | bool         | Only files inside the 'dist' folder will be included in the zip archive.                                                           | no       | `false`                    |
| archive                       | object       | Configure archive file generation                                                                                                  | no       | see sub fields             |
| archive.output_path           | string       | Directory where the zipped file is generated, relative to the terraform file                                                       | no       | `"dist/{name}/lambda.zip"` |
| archive.excludes              | list(string) | List of strings with files that are excluded from the zip file. Only applied when is_bundle is false.                              | no       | `[]`                       |
| cloudwatch                    | object       | CloudWatch configuration                                                                                                           | no       | see sub fields             |
| cloudwatch.retention_in_days  | number       | Retention for the CloudWatch log group                                                                                             | no       | `30`                       |
| cron_trigger                  | object       | Configuration to trigger the lambda through a cron schedule                                                                        | no       | `null`                     |
| cron_trigger.name             | string       | Name of the trigger, must be unique for each lambda                                                                                | no       | `null`                     |
| cron_trigger.description      | string       | Description of the trigger                                                                                                         | no       | `null`                     |
| cron_trigger.schedule         | string       | Schedule expression for the trigger                                                                                                | (yes)    |                            |
| cron_trigger.input            | string       | Valid JSON test passed to the trigger target                                                                                       | no       | `null`                     |
| bucket_trigger                | object       | Configuration to trigger the lambda through bucket events                                                                          | no       | `null`                     |
| bucket_trigger.name           | string       | Name of the trigger                                                                                                                | (yes)    |                            |
| bucket_trigger.bucket         | string       | Name of the bucket                                                                                                                 | (yes)    |                            |
| bucket_trigger.events         | list(string) | List of events that trigger the lambda                                                                                             | (yes)    |                            |
| bucket_trigger.filter_prefix  | string       | Trigger lambda only for files starting with this prefix                                                                            | no       | `null`                     |
| bucket_trigger.filter_suffix  | string       | Trigger lambda only for files starting with this suffix                                                                            | no       | `null`                     |
| sqs_trigger                   | object       | Configuration to trigger lambda through sqs events                                                                                 | no       | `null`                     |
| sqs_trigger.arn               | string       | ARN of the SQS whose event's can trigger lambda function                                                                           | no       | `null`                     |
| role_arn                      | string       | ARN of the role used for executing the lambda function, if no role is given a role with cloudwatch access is created automatically | no       | `null`                     |
| iam_policy                    | list(object) | IAM policies to attach to the lambda role, only works if no custom `role_arn` is set                                               | no       | `[]`                       |
| iam_policy.\*.name            | string       | Name of the policy                                                                                                                 | (yes)    |                            |
| iam_policy.\*.policy          | string       | JSON encoded policy string                                                                                                         | (yes)    |                            |
| environment                   | map(string)  | Map of environment variables that are accessible from the function code during execution                                           | no       | `null`                     |
| vpc_config                    | object       | For network connectivity to AWS resources in a VPC                                                                                 | no       | `null`                     |
| vpc_config.security_group_ids | list(string) | List of security groups to connect the lambda with                                                                                 | (yes)    |                            |
| vpc_config.subnet_ids         | list(string) | List of subnets to attach to the lambda                                                                                            | (yes)    |                            |
| mount_efs                     | string       | ARN of the EFS file system to mount                                                                                                | no       | `null`                     |
| tags                          | map(string)  | Map of tags to assign to the Lambda Function and related resources                                                                 | no       | `{}`                       |

##### Outputs

| Output            | Type   | Description                                                      |
| ----------------- | ------ | ---------------------------------------------------------------- |
| arn               | string | The Amazon Resource Name (ARN) identifying your Lambda Function  |
| function_name     | string | The name of the Lambda Function                                  |
| invoke_arn        | string | The ARN to be used for invoking Lambda Function from API Gateway |
| build             | object | Build output                                                     |
| archive_file_path | string | Path to the generated archive file                               |

#### SNS

```hcl
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "sns" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/sns"
  source                      = "../../../aws/sns"
  description                 = "this is a test topic"
  name                        = local.topic_name
  is_fifo                     = false
  content_based_deduplication = false
  sqs_feedback = {
    sample_rate_in_percent = 100
  }
  access_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect    = "Allow",
        Principal = "*",
        Action : [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:AddPermission",
          "SNS:Subscribe"
        ],
        Resource = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.topic_name}",
      }
    ]
  })


  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}
```

##### Inputs

| Variable                    | Type        | Description                                                                                | Required | Default         |
| --------------------------- | ----------- | ------------------------------------------------------------------------------------------ | -------- | --------------- |
| access_policy               | string      | JSON representation of the access policy.                                                  | yes      |                 |
| description                 | string      | Description of the SNS topic                                                               | yes      |                 |
| name                        | string      | Name of the SNS topic                                                                      | yes      |                 |
| archive_policy              | string      | (FIFO only) JSON representation of the archive policy.                                     | no       | `null`          |
| content_based_deduplication | bool        | Enables or disables deduplication based on the message content                             | no       | `false`         |
| is_fifo                     | bool        | Determines topic type. If `true` creates a FIFO topic, otherwise creates a standard topic. | no       | `true`          |
| kms_master_key_id           | string      | KMS key id used for encryption. Defaults to the AWS managed one.                           | no       | `alias/aws/sns` |
| sqs_feedback                | object      | Configures logging message delivery status to Cloudwatch.                                  | no       | `null`          |
| tags                        | map(string) | Map of tags to assign to the Lambda Function and related resources                         | no       | `{}`            |

##### Outputs

| Output     | Type   | Description                                               |
| ---------- | ------ | --------------------------------------------------------- |
| arn        | string | The Amazon Resource Name (ARN) identifying your SNS topic |
| topic_name | string | The name of the topic                                     |

#### SQS

```hcl
locals {
  queue_name = "they-test-sqs"
}

# ---- DATA ----
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- RESOURCES / MODULES ---
module "sqs" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/sqs"
  source                      = "../../../aws/sqs"
  description                 = "this is a test queue"
  name                        = local.queue_name
  is_fifo                     = false
  content_based_deduplication = false
  max_message_size            = 262144 # 256KB
  message_retention_seconds   = 345600 # 4 days
  visibility_timeout_seconds  = 30
  dead_letter_queue_config = {
    name                      = "${local.queue_name}-dlq"
    max_receive_count         = 1
    message_retention_seconds = 1209600 # 14 days, must be higher than message_retention_seconds in module
  }
  access_policy = jsonencode({ Version = "2012-10-17", Statement = [
    {
      Sid    = "AllowAllSQSActionsToCurrentAccount",
      Effect = "Allow",
      Principal = {
        AWS = data.aws_caller_identity.current.arn
      },
      Action   = ["SQS:*"],
      Resource = "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.queue_name}"
    }
  ]
  })

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

```

##### Inputs

| Variable                       | Type        | Description                                                                          | Required | Default  |
| ------------------------------ | ----------- | ------------------------------------------------------------------------------------ | -------- | -------- |
| access_policy                  | string      | JSON representation of the access policy.                                            | yes      |          |
| description                    | string      | Description of the SQS                                                               | yes      |          |
| name                           | string      | Name of the SQS                                                                      | yes      |          |
| content_based_deduplication    | bool        | Enables or disables deduplication based on the message content                       | no       | `false`  |
| is_fifo                        | bool        | Determines SQS type. If `true` creates a FIFO SQS, otherwise creates a standard SQS. | no       | `true`   |
| max_message_size               | number      | Size-limit of how many bytes a message can be before Amazon SQS rejects it           | no       | `null`   |
| message_retention_seconds      | number      | Number of seconds Amazon SQS retains a message. Defaults to 345600 (4 days)          | no       | `345600` |
| visibility_timeout_seconds     | number      | How long a message remains invisible to other consumers while being consumed.        | no       | `null`   |
| dead_letter_queue_config       | object      | Configuration for the dead letter queue. If provided DLQ will be created.            | no       | `null`   |
| sns_topic_arn_for_subscription | string      | ARN of the SNS topic that the SQS queue will subscribe to, if provided.              | no       | `null`   |
| tags                           | map(string) | Map of tags to assign to the Lambda Function and related resources                   | no       | `{}`     |

##### Outputs

| Output                 | Type   | Description                                                                  |
| ---------------------- | ------ | ---------------------------------------------------------------------------- |
| arn                    | string | The Amazon Resource Name (ARN) identifying your SQS                          |
| queue_name             | string | The name of the SQS                                                          |
| queue_url              | string | The URL of the SQS                                                           |
| topic_subscription_arn | string | The Amazon Resource Name (ARN) of the topic your SQS is subscribed to        |
| dlq_arn                | string | The Amazon Resource Name (ARN) of the dead letter queue created for your SQS |
| dlq_queue_name         | string | The name of the dead letter queue created for your SQS                       |
| dlq_queue_url          | string | The URL of the dead letter queue created for your SQS                        |

#### API Gateway (REST)

```hcl
data "aws_s3_object" "truststore" {
  bucket = "they-test-api-gateway-with-domain-assets"
  key    = "certificates/truststore.pem"
}
module "api_gateway" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"

  name = "they-test-api-gateway"
  description = "Test API Gateway"
  stage_name = "dev"
  logging_level = "INFO"
  metrics_enabled = true

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
    s3_truststore_uri     = "s3://they-test-api-gateway-with-domain-assets/certificates/truststore.pem"
    s3_truststore_version = data.aws_s3_object.truststore.version_id
    zone_name             = "they-code.de."
    domain                = "they-test-lambda.they-code.de"
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
| logging_level                             | string       | Set the logging level for the api gateway                                                                                                                                                                   | no       | `"INFO"`                                                  |
| metrics_enabled                           | bool         | Enables metrics for the api gateway                                                                                                                                                                         | no       | `true`                                                    |
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
| domain.s3_truststore_version              | string       | version of truststore.pem used for verification of client certs (required if multiple versions of a trustore.pem exist)                                                                                     | no       |                                                           |
| domain.zone_name                          | string       | Domain zone name                                                                                                                                                                                            | (yes)    |                                                           |
| disable_default_endpoint                  | string       | Disable the aws generated default endpoint to the created gateway. Can be used to enforce requests only via custom domain. Always `true` if s3_truststore_uri is set.                                       | no       | `false`                                                   |
| redeployment_trigger                      | string       | A unique string to force a redeploy of the api gateway. If not set manually, the module will use the configurations for endpoints, api_key, and authorizer config to decide if a redeployment is necessary. | (yes)    |                                                           |
| tags                                      | map(string)  | Map of tags to assign to the Lambda Function and related resources                                                                                                                                          | no       | `{}`                                                      |

##### Outputs

| Output        | Type         | Description                       |
| ------------- | ------------ | --------------------------------- |
| invoke_url    | string       | The invoke URL of the api gateway |
| endpoint_urls | list(string) | List of all endpoint URLs         |

#### S3 Bucket

```hcl
module "s3_bucket" {
  source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket"

  name       = "my-bucket"
  versioning = true

  lifecycle_rules = [{
    name                = "example-rule",
    prefix              = "they",
    days                = 60,
    noncurrent_days     = 30,
    noncurrent_versions = 10
  }]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::my-bucket",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = ["arn:aws:iam::0123456789:*"]
          },
          ArnLike = {
            "aws:SourceArn" = ["arn:aws:logs::0123456789:*"]
          }
        }
      }
    ]
  })

  prevent_destroy = true
}
```

##### Inputs

| Variable                               | Type         | Description                                                                                                                                          | Required | Default |
| -------------------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| name                                   | string       | Name of the bucket                                                                                                                                   | yes      |         |
| versioning                             | bool         | Enable versioning of s3 bucket                                                                                                                       | yes      |         |
| policy                                 | string       | Policy of s3 bucket                                                                                                                                  | no       | `null`  |
| prevent_destroy                        | bool         | Prevent destroy of s3 bucket. To bypass this protection even if this is enabled, remove the module from your code and run `terraform apply`          | no       | `true`  |
| lifecycle_rules                        | list(object) | List of rules as objects with lifetime (in days) of the S3 objects that are subject to the policy and path prefix                                    | no       | `[]`    |
| lifecycle_rules.\*.name                | string       | Rule name                                                                                                                                            | (yes)    |         |
| lifecycle_rules.\*.prefix              | string       | Prefix identifying one or more objects to which the rule applies                                                                                     | no       | `""`    |
| lifecycle_rules.\*.days                | number       | The lifetime, in days, of the objects that are subject to the rule. Afterwards objects become noncurrent. Must be a non-zero positive integer if set | no       | `null`  |
| lifecycle_rules.\*.noncurrent_days     | number       | The number of days an object is noncurrent before the object will be deleted. Must be a positive integer if set                                      | no       | `null`  |
| lifecycle_rules.\*.noncurrent_versions | number       | The number of noncurrent versions Amazon S3 will retain. Must be a non-zero positive integer if set                                                  | no       | `null`  |

##### Outputs

| Output     | Type   | Description                    |
| ---------- | ------ | ------------------------------ |
| id         | string | ID of the s3 bucket            |
| arn        | string | ARN of the s3 bucket           |
| versioning | string | ID of the s3 bucket versioning |

#### S3 Log Bucket Policy

```hcl
module "s3_log_bucket_policy" {
  source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket/log-bucket-policy"

  bucket_name = "my-bucket"
}
```

##### Inputs

| Variable | Type   | Description        | Required | Default |
| -------- | ------ | ------------------ | -------- | ------- |
| name     | string | Name of the bucket | yes      |         |

##### Outputs

| Output   | Type         | Description                                             |
| -------- | ------------ | ------------------------------------------------------- |
| policies | list(object) | List of policies that can be used in a policy statement |

#### Auto Scaling Group

```hcl
data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_acm_certificate" "certificate" {
  domain   = "they-code.de"
  statuses = ["ISSUED"]
}

module "auto-scaling-group" {
  source = "github.com/THEY-Consulting/they-terraform//aws/auto-scaling-group"

  name        = "they-terraform-test-asg"
  ami_id = "ami-0ba27d9989b7d8c5d" # AMI valid for eu-central-1 (Amazon Linux 2023 arm64).
  instance_type = "t4g.nano"
  desired_capacity = 2
  min_size = 1
  max_size = 3
  key_name = "they-test"
  user_data_file_name = "user_data.sh" # or
  use_data = base64encode(templatefile("cloud_init.yaml", {
    environment = var.environment
  }))
  availability_zones = data.aws_availability_zones.azs.names[*] # Use AZs of region defined by provider.
  single_availability_zone = false
  vpc_id = "vpc-1234567890"
  vpc_cidr_block = "10.0.0.0/16"
  public_subnets = false
  certificate_arn = data.aws_acm_certificate.certificate.arn
  tags = {
    createdBy = "terraform"
    environment = "dev"
  }
  health_check_path = "/health"
  target_groups = [{
    name = "api"
    port = 8080
    health_check_path = "/health"
    path_priority = 100
    path_patterns_forwarded_to_target_group_on_default_port = tolist(["/api/*", "/v1"])
  }]
  policies = [{
    name = "ecr_pull"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ],
          Effect   = "Allow"
          Resource = "${var.bucket_arn}/*"
        }
      ]
    })
  }]
  permissions_boundary_arn = "arn:aws:iam::123456789012:policy/they-test-boundary"
  allow_all_outbound = false
  allow_ssh_inbound = false
  multi_az_nat = true
  manual_lifecycle = false
  manual_lifecycle_timeout = 300
  access_logs = {
    bucket = "they-test-logs"
    prefix = "asg-logs"
  }
}

```

##### Inputs

| Variable                                                                 | Type         | Description                                                                                                                                                             | Required | Default                                                                   |
| ------------------------------------------------------------------------ | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------- |
| name                                                                     | string       | Name of the Auto Scaling Group (ASG)                                                                                                                                    | yes      |                                                                           |
| ami_id                                                                   | string       | ID of AMI used in EC2 instances of ASG                                                                                                                                  | yes      |                                                                           |
| instance_type                                                            | string       | Instance type used to deploy instances in ASG                                                                                                                           | yes      |                                                                           |
| desired_capacity                                                         | number       | The number of EC2 instances that will be running in the ASG                                                                                                             | no       | `1`                                                                       |
| min_size                                                                 | number       | The minimum number of EC2 instances in the ASG                                                                                                                          | no       | `1`                                                                       |
| max_size                                                                 | number       | The maximum number of EC2 instances in the ASG                                                                                                                          | no       | `1`                                                                       |
| min_instance_storage_size_in_gb                                          | number       | The storage size of the root EBS volume of the deployed EC2 instances                                                                                                   | no       | The storage AWS automatically allocates for your instance type by default |
| key_name                                                                 | string       | Name of key pair used for the instances                                                                                                                                 | no       | `null`                                                                    |
| user_data_file_name                                                      | string       | The name of the local file in the working directory with the user data used in the instances of the ASG                                                                 | no       | `null`                                                                    |
| user_data                                                                | string       | User data to provide when launching instances of ASG. Use this to provide plain text instead of user_data_file_name                                                     | no       | `null`                                                                    |
| availability_zones                                                       | list(string) | List of availability zones (AZs) names. A subnet is created for every AZ and the ASG instances are deployed across the different AZs                                    | yes      |                                                                           |
| single_availability_zone                                                 | bool         | Specify true to deploy all ASG instances in the same zone. Otherwise, the ASG will be deployed across multiple availability zones                                       | no       | `false`                                                                   |
| vpc_id                                                                   | string       | ID of VPC where the ASG will be deployed. If not provided, a new VPC will be created.                                                                                   | no       | `null`                                                                    |
| vpc_cidr_block                                                           | string       | The CIDR block of private IP addresses of the VPC. The subnets will be located within this CIDR block.                                                                  | no       | `"10.0.0.0/16"`                                                           |
| public_subnets                                                           | bool         | Specify true to indicate that instances launched into the subnets should be assigned a public IP address                                                                | no       | `false`                                                                   |
| certificate_arn                                                          | string       | ARN of certificate used to setup HTTPs in Application Load Balancer                                                                                                     | no       | `null`                                                                    |
| tags                                                                     | map(string)  | Additional tags for the components of this module                                                                                                                       | no       | `{}`                                                                      |
| health_check_path                                                        | string       | Destination for the health check request                                                                                                                                | no       | `"/"`                                                                     |
| target_groups                                                            | list(object) | List of additional target groups to attach to the ASG instances and forward traffic to                                                                                  | no       | `[]`                                                                      |
| target_groups.\*.name                                                    | string       | Name of the target group                                                                                                                                                | (yes)    |                                                                           |
| target_groups.\*.port                                                    | number       | Port of the target group                                                                                                                                                | (yes)    |                                                                           |
| target_groups.\*.health_check_path                                       | string       | Destination for the health check request for the target group                                                                                                           | no       | `"/"`                                                                     |
| target_groups.\*.path_patterns_forwarded_to_target_group_on_default_port | list(string) | URL path patterns on default port (HTTPs or HTTP) that will be forwarded to the target group                                                                            | no       | `null`                                                                    |
| target_groups.\*.path_priority                                           | number       | The priority for the rule between 1 and 50000. Leaving it unset will automatically set the rule with next available priority after the currently existing highest rule. | no       | `null`                                                                    |
| policies                                                                 | list(object) | List of policies to attach to the ASG instances via IAM Instance Profile                                                                                                | no       | `[]`                                                                      |
| policies.\*.name                                                         | string       | Name of the inline policy                                                                                                                                               | yes      |                                                                           |
| policies.\*.policy                                                       | string       | Policy document as a JSON formatted string                                                                                                                              | yes      |                                                                           |
| permissions_boundary_arn                                                 | string       | ARN of the permissions boundary to attach to the IAM Instance Profile                                                                                                   | no       | `null`                                                                    |
| allow_all_outbound                                                       | bool         | Allow all outbound traffic from instances                                                                                                                               | no       | `false`                                                                   |
| allow_ssh_inbound                                                        | bool         | Allow ssh inbound traffic from outside the VPC                                                                                                                          | no       | `false`                                                                   |
| health_check_type                                                        | string       | Controls how the health check for the EC2 instances under the ASG is done                                                                                               | no       | `"ELB"`                                                                   |
| multi_az_nat                                                             | bool         | Specify true to deploy a NAT Gateway in each availability zone (AZ) of the deployment. Otherwise, only a single NAT Gateway will be deployed                            | no       | `false`                                                                   |
| loadbalancer_disabled                                                    | bool         | Specify true to use the ASG without an ELB. By default, an ELB will be used                                                                                             | no       | `false`                                                                   |
| manual_lifecycle                                                         | bool         | Specify true to force the asg to wait until lifecycle actions are completed before adding instances to the load balancer                                                | no       | `false`                                                                   |
| manual_lifecycle_timeout                                                 | number       | The maximum time, in seconds, that an instance can remain in a Pending:Wait state                                                                                       | no       | `null`                                                                    |
| access_logs                                                              | object       | Enables access logs                                                                                                                                                     | no       | `null`                                                                    |
| access_logs.bucket                                                       | string       | Name of the bucket where the access logs are stored                                                                                                                     | (yes)    |                                                                           |
| access_logs.prefix                                                       | string       | Prefix for access logs within the s3 bucket, use this to set the folder within the bucket                                                                               | (yes)    |                                                                           |

##### Outputs

| Output                         | Type         | Description                                         |
| ------------------------------ | ------------ | --------------------------------------------------- |
| alb_dns                        | string       | DNS of the Application Load Balancer of the ASG     |
| alb_zone_id                    | string       | Zone ID of the Application Load Balancer of the ASG |
| asg_arn                        | string       | ARN of the ASG                                      |
| asg_name                       | string       | Name of the ASG                                     |
| nat_gateway_ips                | list(string) | Public IPs of the NAT gateways                      |
| security_group_id              | string       | ID of the security group                            |
| private_subnet_ids             | list(string) | IDs of the private subnets                          |
| public_subnet_ids              | list(string) | IDs of the public subnets                           |
| private_subnet_route_table_ids | list(string) | IDs of the route tables for the private subnets     |
| vpc_id                         | string       | ID of the VPC                                       |

#### CloudFront Distribution

```hcl
module "cloudfront_distribution" {
  #   source = "github.com/THEY-Consulting/they-terraform//aws/cloudfront"
  source = "../../../aws/cloudfront"

  name                 = "they-test"
  domain               = "test.they-code.de"
  certificate_arn      = "some:certificate:arn"
  attach_domain        = true
  bucket_name          = "they-test-bucket"
  attach_bucket_policy = true
  origin_name          = "s3-origin"
  origin_path          = "/dev"
  cloudfront_routing   = "simple"
}
```

##### Inputs

| Variable             | Type   | Description                                                           | Required | Default    |
| -------------------- | ------ | --------------------------------------------------------------------- | -------- | ---------- |
| name                 | string | Name of CloudFront distribution                                       | yes      |            |
| domain               | string | The domain name for the CloudFront distribution                       | yes      |            |
| certificate_arn      | string | The ARN of the certificate to use for HTTPS                           | yes      |            |
| attach_domain        | bool   | Whether to attach the domain to the CloudFront distribution           | no       | `true`     |
| bucket_name          | string | The S3 bucket to use as the origin for the CloudFront distribution    | yes      |            |
| attach_bucket_policy | bool   | Whether to attach a bucket policy to the S3 bucket                    | no       | `true`     |
| origin_name          | string | The name of the origin                                                | no       | `"s3"`     |
| origin_path          | string | The path within the origin                                            | no       | `""`       |
| cloudfront_routing   | string | The CloudFront routing configuration, valid are `simple` and `branch` | no       | `"simple"` |

##### Outputs

| Output         | Type   | Description                                   |
| -------------- | ------ | --------------------------------------------- |
| domain_name    | string | Domain name of the CloudFront distribution    |
| hosted_zone_id | string | Hosted zone id of the CloudFront distribution |
| arn            | string | ARN of the CloudFront distribution            |
| id             | string | Id of the CloudFront distribution             |

#### Azure OpenID role

```hcl
module "azure_openid" {
  source = "github.com/THEY-Consulting/they-terraform//aws/openid/azure"

  name = "they-test"

  azure_resource_group_name = "they-dev"
  azure_location            = "Germany West Central"
  azure_identity_name = "existing-identity-name"

  policies = [
    {
      name = "they-test-policy"
      policy = jsonencode({
        Version : "2012-10-17",
        Statement : [
          {
            Effect : "Allow",
            Action : [
              "dynamodb:Query",
            ],
            Resource : [
              "arn:aws:dynamodb:::table/they-test-table",
            ]
          }
        ]
      })
    },
  ],
  inline = true
  boundary_policy_arn = "arn:aws:iam::123456789012:policy/they-test-boundary"
  INSECURE_allowAccountToAssumeRole = false # Do not enable this in production!
}
```

##### Inputs

| Variable                          | Type         | Description                                                                                                                                                                                                   | Required | Default |
| --------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| name                              | string       | Name of the role                                                                                                                                                                                              | yes      |         |
| azure_resource_group_name         | string       | The Azure resource group                                                                                                                                                                                      | yes      |         |
| azure_location                    | string       | The Azure region                                                                                                                                                                                              | yes      |         |
| azure_identity_name               | string       | Name of an existing azure identity, if not provided, a new one will be created                                                                                                                                | no       | `null`  |
| policies                          | list(object) | List of additional inline policies to attach to the app                                                                                                                                                       | no       | `[]`    |
| policies.\*.name                  | string       | Name of the inline policy                                                                                                                                                                                     | yes      |         |
| policies.\*.policy                | string       | Policy document as a JSON formatted string                                                                                                                                                                    | yes      |         |
| inline                            | bool         | If true, the policies will be created as inline policies. If false, they will be created as managed policies. Changing this will not necessarily remove the old policies correctly, check in the AWS console! | no       | `true`  |
| boundary_policy_arn               | string       | ARN of a boundary policy to attach to the app                                                                                                                                                                 | no       | `null`  |
| INSECURE_allowAccountToAssumeRole | bool         | Set to true if you want to allow the account to assume the role. This is insecure and should only be used for testing. Do not enable this in production!                                                      | no       | `false` |

##### Outputs

| Output             | Type   | Description                     |
| ------------------ | ------ | ------------------------------- |
| role_name          | string | The name of the role            |
| role_arn           | string | The ARN of the role             |
| identity_name      | string | Name of the azure identity      |
| identity_client_id | string | Client Id of the azure identity |

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
  ]
  inline                            = false
  INSECURE_allowAccountToAssumeRole = false # Do not enable this in production!
  boundary_policy_arn               = "arn:aws:iam::123456789012:policy/they-test-boundary"

  include_default_policies = {
    s3StateBackend                = true
    cloudwatch                    = true
    cloudfront                    = true
    cloudfront_source_bucket_arns = ["arn:aws:s3:::they-test-deployment-bucket"]
    asg                           = true
    iam                           = true
    delegated_boundary_arn        = "arn:aws:iam::123456789012:policy/they-test-boundary"
    instance_key_pair_name        = "test-key"
    route53                       = true
    host_zone_arn                 = "arn:aws:route53:::hostedzone/Z1234567890"
    route53_records               = ["test*.they-code.de", "_test*.they-code.de"]
    certificate_arns              = ["arn:aws:acm:::certificate/1234567890"]
    dynamodb                      = true
    dynamodb_table_names          = ["they-test-table"]
    ecr                           = true
    ecr_repository_arns           = ["arn:aws:ecr:::repository/they-test-repo"]
  }
}
```

##### Inputs

| Variable                                               | Type         | Description                                                                                                                                                                                                   | Required | Default                                             |
| ------------------------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------------------------------------- |
| name                                                   | string       | Name of the role                                                                                                                                                                                              | yes      |                                                     |
| repo                                                   | string       | Repository that is authorized to assume this role                                                                                                                                                             | yes      |                                                     |
| policies                                               | list(object) | List of additional inline policies to attach to the app                                                                                                                                                       | no       | `[]`                                                |
| policies.\*.name                                       | string       | Name of the inline policy                                                                                                                                                                                     | yes      |                                                     |
| policies.\*.policy                                     | string       | Policy document as a JSON formatted string                                                                                                                                                                    | yes      |                                                     |
| inline                                                 | bool         | If true, the policies will be created as inline policies. If false, they will be created as managed policies. Changing this will not necessarily remove the old policies correctly, check in the AWS console! | no       | `true`                                              |
| INSECURE_allowAccountToAssumeRole                      | bool         | Set to true if you want to allow the account to assume the role. This is insecure and should only be used for testing. Do not enable this in production!                                                      | no       | `false`                                             |
| boundary_policy_arn                                    | string       | ARN of a boundary policy to attach to the app                                                                                                                                                                 | no       | `null`                                              |
| include_default_policies                               | object       | Configure the default policies that should be included in the role                                                                                                                                            | no       | `"{}"`                                              |
| include_default_policies.s3StateBackend                | bool         | Set to true if a s3 state backend was setup with the setup-tfstate module (or uses the same naming scheme for the s3 bucket and dynamoDB table). This will set the required s3 and dynamoDB permissions.      | no       | `true`                                              |
| include_default_policies.stateLockTableRegion          | string       | Region of the state lock table, if different from the default region                                                                                                                                          | no       | `""`                                                |
| include_default_policies.cloudwatch                    | bool         | Set to true if the app uses CloudWatch                                                                                                                                                                        | no       | `false`                                             |
| include_default_policies.cloudfront                    | bool         | Set to true if the app uses CloudFront                                                                                                                                                                        | no       | `false`                                             |
| include_default_policies.cloudfront_source_bucket_arns | list(string) | The ARNs of the S3 buckets that are allowed as CloudFront sources, required if `cloudfront` is true                                                                                                           | (yes)    | `null`                                              |
| include_default_policies.asg                           | bool         | Set to true if the app uses an Auto Scaling Group                                                                                                                                                             | no       | `false`                                             |
| include_default_policies.ami_condition                 | object       | The condition that must be met by AMIs that are used to launch instances                                                                                                                                      | no       | `{"ec2:ImageType":"machine", "ec2:Owner":"amazon"}` |
| include_default_policies.iam                           | bool         | Set to true if the app uses IAM roles, setting `asg` to true will automatically enable this as well                                                                                                           | no       | `false`                                             |
| include_default_policies.delegated_boundary_arn        | string       | The ARN of the IAM policy that is used as the permissions boundary for newly created roles, required if `iam` or `asg` is true                                                                                | (yes)    | `null`                                              |
| include_default_policies.instance_key_pair_name        | string       | The name of the key pair that is used to launch instances, required if `iam` or `asg` is true                                                                                                                 | (yes)    | `""`                                                |
| include_default_policies.route53                       | bool         | Set to true if the app uses Route 53                                                                                                                                                                          | no       | `false`                                             |
| include_default_policies.host_zone_arn                 | string       | The ARN of the Route 53 Hosted Zone that is used for the domain, required if `route53` is true                                                                                                                | (yes)    | `null`                                              |
| include_default_policies.route53_records               | list(string) | The Route 53 records that are allowed to be created, supports wildcards, required if `route53` is true                                                                                                        | (yes)    | `null`                                              |
| include_default_policies.certificate_arns              | list(string) | The ARNs of the ACM certificates that are allowed to be used, required if `route53` is true                                                                                                                   | (yes)    | `null`                                              |
| include_default_policies.dynamodb                      | bool         | Set to true if the app uses DynamoDB                                                                                                                                                                          | no       | `false`                                             |
| include_default_policies.dynamodb_table_names          | list(string) | The Names of DynamoDB tables that are allowed to be managed, required if `dynamodb` is true                                                                                                                   | (yes)    | `null`                                              |
| include_default_policies.ecr                           | bool         | Set to true if the app uses ECR                                                                                                                                                                               | no       | `false`                                             |
| include_default_policies.ecr_repository_arns           | list(string) | The ARNs of the ECR repositories that are allowed to be accessed, required if `ecr` is true                                                                                                                   | (yes)    | `null`                                              |
| s3StateBackend                                         | bool         | @Deprecated: use `include_default_policies.s3StateBackend` instead                                                                                                                                            | no       | `true`                                              |
| stateLockTableRegion                                   | string       | @Deprecated: use `include_default_policies.stateLockTableRegion` instead                                                                                                                                      | no       | `""`                                                |

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

#### Outbound proxy VPC

Whenever you need to talk to APIs which use IP based whitelisting, this is
the module to create the required setup with. It uses an eip/elastic ip (will be created if none is given)
and it spits out a vpc_config which can be attached to a lambda function. The
lambda function will then execute requests via the ip of the given eip.

```hcl
module "outbound_proxy_vpc" {
  source = "../../../aws/lambda/outbound-proxy-vpc"

  name = local.name
}

module "lambda_with_outbound_proxy" {
  source = "../../../aws/lambda"
  vpc_config  = module.outbound_proxy_vpc.vpc_config

  name        = local.name
  description = "Test lambda with outbound proxy"
  source_dir  = "../packages/lambda-outbound-proxy"
  runtime     = "nodejs20.x"

}
```

##### Inputs

| Name                                                                                 | Description                                                                                                          | Type          | Required | Default |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- | ------------- | -------- | :-----: |
| <a name="input_eip_allocation_id"></a> [eip_allocation_id](#input_eip_allocation_id) | The allocation id of the elastic ip address. The public ip of this eip will be used as the outbound ip of the proxy. | `string`      | no       | `null`  |
| <a name="input_name"></a> [name](#input_name)                                        | Name/Prefix of resources created by this module.                                                                     | `string`      | no       |  null   |
| <a name="input_tags"></a> [tags](#input_tags)                                        | Map of tags to assign to the created resources of this module.                                                       | `map(string)` | no       |  `{}`   |

##### Outputs

| Name                                                              | Description                                                                                       |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| <a name="output_vpc_arn"></a> [vpc_arn](#output_vpc_arn)          | Arn of the created vpc.                                                                           |
| <a name="output_vpc_config"></a> [vpc_config](#output_vpc_config) | By attaching this config to the vpc_config block of a lambda function it uses the outbound proxy. |

### Azure

#### Function app

```hcl
module "function_app" {
  source = "github.com/THEY-Consulting/they-terraform//azure/function-app"

  name                = "they-test"
  source_dir          = "packages/function-app"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  storage_account = {
    preexisting_name = "theydev"
    is_hns_enabled   = true
    tier             = "Standard"
    replication_type = "RAGRS"
    min_tls_version  = "TLS1_2"
  }

  service_plan = {
    name     = "they-test"
    sku_name = "Y1"
  }

  insights = {
    enabled           = true
    sku               = "PerGB2018"
    retention_in_days = 30
  }

  runtime = {
    name = "node"
    version = "~18"
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
  assign_system_identity = true

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}
```

##### Inputs

| Variable                                           | Type         | Description                                                                                                             | Required | Default                                |
| -------------------------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------- |
| name                                               | string       | Name of the function app                                                                                                | yes      |                                        |
| source_dir                                         | string       | Directory containing the function code                                                                                  | yes      |                                        |
| location                                           | string       | The Azure region where the resources should be created                                                                  | yes      |                                        |
| resource_group_name                                | string       | The name of the resource group in which to create the function app                                                      | yes      |                                        |
| storage_account                                    | object       | The storage account                                                                                                     | no       | see sub fields                         |
| storage_account.preexisting_name                   | string       | Name of an existing storage account, if this is `null` a new storage account will be created                            | no       | `null`                                 |
| storage_account.is_hns_enabled                     | bool         | Makes the storage account a "data lake storage" if enabled.                                                             | no       | `false`                                |
| storage_account.tier                               | string       | Tier of the newly created storage account, ignored if `storage_account.preexisting_name` is set                         | no       | `"Standard"`                           |
| storage_account.replication_type                   | string       | Replication type of the newly created storage account, ignored if `storage_account.preexisting_name` is set             | no       | `"RAGRS"`                              |
| storage_account.min_tls_version                    | string       | Min TLS version of the newly created storage account, ignored if `storage_account.preexisting_name` is set              | no       | `"TLS1_2"`                             |
| service_plan                                       | object       | The service plan                                                                                                        | no       | see sub fields                         |
| service_plan.name                                  | string       | Name of an existing service plan, if this is `null` a new service plan will be created                                  | no       | `null`                                 |
| service_plan.sku_name                              | string       | SKU name of the service plan, ignored if `service_plan.name` is set                                                     | no       | `"Y1"`                                 |
| insights                                           | object       | Application insights                                                                                                    | no       | see sub fields                         |
| insights.enabled                                   | bool         | Enable/Disable application insights                                                                                     | no       | `true`                                 |
| insights.sku                                       | string       | SKU for application insights                                                                                            | no       | `"PerGB2018"`                          |
| insights.retention_in_days                         | number       | Retention for application insights in days                                                                              | no       | `30`                                   |
| runtime                                            | object       | The runtime environment                                                                                                 | no       | see sub fields                         |
| runtime.name                                       | string       | The runtime environment name, valid values are `dotnet`, `java`, `node`, and `powershell`. Linux also supports `python` | no       | `"node"`                               |
| runtime.version                                    | string       | The runtime environment version. Depends on the runtime.                                                                | no       | `"~18"`                                |
| runtime.os                                         | string       | The os where the function app runs, valid values are `windows` and `linux`                                              | no       | `"windows"`                            |
| environment                                        | map(string)  | Map of environment variables that are accessible from the function code during execution                                | no       | `{}`                                   |
| build                                              | object       | Build configuration                                                                                                     | no       | see sub fields                         |
| build.enabled                                      | bool         | Enable/Disable running build command                                                                                    | no       | `true`                                 |
| build.command                                      | string       | Build command to use                                                                                                    | no       | `"yarn run build"`                     |
| build.build_dir                                    | string       | Directory where the compiled lambda files are generated, relative to the lambda source directory                        | no       | `"dist"`                               |
| is_bundle                                          | bool         | If true, node_modules and .yarn directories will be excluded from the archive.                                          | no       | `false`                                |
| archive                                            | object       | Archive configuration                                                                                                   | no       | see sub fields                         |
| archive.output_path                                | string       | Directory where the zipped file is generated, relative to the terraform file                                            | no       | `"dist/{name}/azure-function-app.zip"` |
| archive.excludes                                   | list(string) | List of strings with files that are excluded from the zip file                                                          | no       | `[]`                                   |
| storage_trigger                                    | object       | Trigger the azure function through storage event grid subscription                                                      | no       | `null`                                 |
| storage_trigger.function_name                      | string       | Name of the function that should be triggered                                                                           | (yes)    |                                        |
| storage_trigger.events                             | list(string) | List of event names that should trigger the function                                                                    | (yes)    |                                        |
| storage_trigger.subject_filter                     | object       | filter events for the event subscription                                                                                | no       | `null`                                 |
| storage_trigger.subject_filter.subject_begins_with | string       | A string to filter events for an event subscription based on a resource path prefix                                     | no       | `null`                                 |
| storage_trigger.subject_filter.subject_ends_with   | string       | A string to filter events for an event subscription based on a resource path suffix                                     | no       | `null`                                 |
| storage_trigger.retry_policy                       | object       | Retry policy                                                                                                            | no       | see sub fields                         |
| storage_trigger.retry_policy.event_time_to_live    | number       | Specifies the time to live (in minutes) for events                                                                      | no       | `360`                                  |
| storage_trigger.retry_policy.max_delivery_attempts | number       | Specifies the maximum number of delivery retry attempts for events                                                      | no       | `1`                                    |
| identity                                           | object       | Identity to use                                                                                                         | no       | `null`                                 |
| identity.name                                      | string       | Name of the identity                                                                                                    | (yes)    |                                        |
| assign_system_identity                             | bool         | If true, a system identity will be assigned to the function app.                                                        | no       | `false`                                |
| tags                                               | map(string)  | Map of tags to assign to the function app and related resources                                                         | no       | `{}`                                   |

##### Outputs

| Output            | Type         | Description                        |
| ----------------- | ------------ | ---------------------------------- |
| id                | string       | The ID of the Function App         |
| name              | string       | The name of the Function App       |
| build             | string       | Build output                       |
| archive_file_path | string       | Path to the generated archive file |
| endpoint_url      | string       | Endpoint URL                       |
| identities        | list(object) | Identities if some were assigned   |

#### MSSQL Database

```hcl
module "mssql_database" {
  source = "github.com/THEY-Consulting/they-terraform//azure/database/mssql"

  name                = "they-test-database"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  server = {
    preexisting_name             = "some-existing-server"
    version                      = "12.0"
    administrator_login          = "AdminUser"
    administrator_login_password = "P@ssw0rd123!"
    allow_azure_resources        = true
    allow_all                    = true
    firewall_rules = [
      {
        name             = "AllowAll"
        start_ip_address = "0.0.0.0"
        end_ip_address   = "255.255.255.255"
      }
    ]
  }

  users = [
    {
      username = "they-test-user"
      password = sensitive("P@ssw0rd123!")
      roles    = ["db_owner"]
    },
    {
      username = "they-test-user-read"
      password = sensitive("P@ssw0rd123!")
      roles    = ["db_datareader"]
    }
  ]

  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name                    = "GP_S_Gen5_1"
  max_size_gb                 = 16
  min_capacity                = 0.5
  storage_account_type        = "Local"
  auto_pause_delay_in_minutes = 60

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}
```

##### Inputs

| Variable                               | Type         | Description                                                                                                                                                                                              | Required | Default                          |
| -------------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------------- |
| name                                   | string       | Name of the database                                                                                                                                                                                     | yes      |                                  |
| location                               | string       | The Azure region where the resources should be created                                                                                                                                                   | yes      |                                  |
| resource_group_name                    | string       | The name of the resource group in which to create the resources                                                                                                                                          | yes      |                                  |
| server                                 | object       | The database server                                                                                                                                                                                      | yes      |                                  |
| server.preexisting_name                | string       | Name of an existing database server, if this is `null` a new database server will be created                                                                                                             | no       | `null`                           |
| server.version                         | string       | Version of the MSSQL database, ignored if `server.preexisting_name` is set                                                                                                                               | no       | `12.0`                           |
| server.administrator_login             | string       | Name of the administrator login, ignored if `server.preexisting_name` is set                                                                                                                             | no       | `"AdminUser"`                    |
| server.administrator_login_password    | string       | Password of the administrator login, ignored if `server.preexisting_name` is set, required otherwise                                                                                                     | yes\*    |                                  |
| server.allow_azure_resources           | bool         | Adds a database server firewall rule to grant database access to azure resources, ignored if `server.preexisting_name` is set                                                                            | no       | `true`                           |
| server.allow_all                       | bool         | Adds a database server firewall rule to grant database access to everyone, ignored if `server.preexisting_name` is set                                                                                   | no       | `false`                          |
| server.firewall_rules                  | list(object) | Adds server firewall rules, ignored if `server.preexisting_name` is set                                                                                                                                  | no       | `[]`                             |
| server.firewall_rules.name             | string       | Name of the firewall rule                                                                                                                                                                                | yes      |                                  |
| server.firewall_rules.start_ip_address | string       | Start ip address of the firewall rule                                                                                                                                                                    | yes      |                                  |
| server.firewall_rules.end_ip_address   | string       | End ip address of the firewall rule                                                                                                                                                                      | yes      |                                  |
| users                                  | list(object) | List of users (with logins) to create in the database                                                                                                                                                    | no       | `[]`                             |
| users.username                         | string       | Name for the user and login                                                                                                                                                                              | yes      |                                  |
| users.password                         | string       | Password for the user login                                                                                                                                                                              | yes      |                                  |
| users.roles                            | list(string) | List of roles to attach to the user                                                                                                                                                                      | yes      |                                  |
| collation                              | string       | The collation of the database                                                                                                                                                                            | no       | `"SQL_Latin1_General_CP1_CI_AS"` |
| sku_name                               | string       | The sku for the database. For vCores, this also sets the maximum capacity                                                                                                                                | no       | `"GP_S_Gen5_1"`                  |
| max_size_gb                            | number       | The maximum size of the database in gigabytes                                                                                                                                                            | no       | `16`                             |
| min_capacity                           | number       | The minimum vCore of the database. The maximum is set by the sku tier. Only relevant when using a serverless vCore based database. Set this to 0 otherwise.                                              | no       | `0.5`                            |
| storage_account_type                   | string       | The storage account type used to store backups for this database. Possible values are Geo, Local and Zone                                                                                                | no       | `"Local"`                        |
| auto_pause_delay_in_minutes            | number       | Time in minutes after which database is automatically paused. A value of -1 means that automatic pause is disabled. Only relevant when using a serverless vCore based database. Set this to 0 otherwise. | no       | `60`                             |
| tags                                   | map(string)  | Map of tags to assign to the resources                                                                                                                                                                   | no       | `{}`                             |

##### Outputs

| Output                     | Type   | Description                                                |
| -------------------------- | ------ | ---------------------------------------------------------- |
| database_name              | string | Name of the database                                       |
| server_administrator_login | string | Administrator login name                                   |
| server_domain_name         | string | Domain name of the server                                  |
| ODBC_connection_string     | string | OBDC Connection string with a placeholder for the password |

#### VM

```hcl
module "vm" {
  source = "github.com/THEY-Consulting/they-terraform//azure/vm"

  name                = "they-test-vm"
  resource_group_name = "they-dev"

  vm_hostname       = "vm"
  vm_os             = "linux"
  vm_size           = "Standard_B2s"
  vm_username       = "they"
  vm_password       = "P@ssw0rd123!"
  vm_public_ssh_key = file("key.pub")
  custom_data = base64encode(templatefile("setup_instance.yml", {
    hello = "world"
  }))
  vm_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  network = {
    preexisting_name = "they-dev-vnet"
    address_space    = ["10.0.0.0/16"]
  }
  subnet_address_prefix = "10.0.0.0/24"
  routes = [{
    name           = "all_traffic"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }]
  public_ip = true

  allow_ssh = true
  allow_rdp = true
  security_rules = [{
    name                   = "mock-server"
    priority               = 200
    destination_port_range = "80"
  }]

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}
```

##### Inputs

| Variable                              | Type         | Description                                                                                      | Required | Default                                                                                |
| ------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------ | -------- | -------------------------------------------------------------------------------------- |
| name                                  | string       | Name of the vm and related resources                                                             | yes      |                                                                                        |
| resource_group_name                   | string       | The name of the resource group in which to create the resources                                  | yes      |                                                                                        |
| vm_hostname                           | string       | Hostname of the vm                                                                               | no       | `var.name`                                                                             |
| vm_os                                 | string       | The OS to use for the VM. Valid values are 'linux' or 'windows'                                  | no       | `"linux"`                                                                              |
| vm_size                               | string       | The size of the VM to create                                                                     | no       | `"Standard_B2s"`                                                                       |
| vm_username                           | string       | The username for the VM admin user                                                               | no       | `"they"`                                                                               |
| vm_password                           | string       | The password of the VM admin user                                                                | yes      |                                                                                        |
| vm_public_ssh_key                     | string       | Public SSH key to use for the VM, required for linux VMs                                         | yes\*    |                                                                                        |
| custom_data                           | string       | The custom data to setup the VM                                                                  | no       | `null`                                                                                 |
| vm_image                              | object       | The image to use for the VM                                                                      | no       | see sub fields                                                                         |
| vm_image.publisher                    | string       | Publisher of the VM image                                                                        | no       | `"Canonical"`                                                                          |
| vm_image.offer                        | string       | Offer of the VM image                                                                            | no       | `"0001-com-ubuntu-server-jammy"`                                                       |
| vm_image.sku                          | string       | SKU of the VM image                                                                              | no       | `"22_04-lts-gen2"`                                                                     |
| vm_image.version                      | string       | Version of the VM image                                                                          | no       | `"latest"`                                                                             |
| network                               | object       | The network config to use for the VM                                                             | no       | see sb fields                                                                          |
| network.preexisting_name              | string       | Name of an existing network that should be used, if this is `null` a new network will be created | no       | `null`                                                                                 |
| network.address_space                 | list(string) | List of address spaces for the network, ignored if `preexisting_name` is not `null`              | no       | `["10.0.0.0/16"]`                                                                      |
| subnet_address_prefix                 | string       | The address prefix to use for the subnet                                                         | no       | `"10.0.0.0/24"`                                                                        |
| routes                                | list(object) | The routes to use for the VM                                                                     | no       | `[{ name = "all_traffic", address_prefix = "0.0.0.0/0", next_hop_type = "Internet" }]` |
| routes.name                           | string       | Name of the route                                                                                | yes      |                                                                                        |
| routes.address_prefix                 | string       | Address prefix of the route                                                                      | yes      |                                                                                        |
| routes.next_hop_type                  | string       | Next hop type of the route                                                                       | yes      |                                                                                        |
| public_ip                             | bool         | Enable a static public IP for the VM                                                             | no       | `false`                                                                                |
| allow_ssh                             | bool         | Allow SSH access to the VM                                                                       | no       | `false`                                                                                |
| allow_rdp                             | bool         | Allow RDP access to the VM                                                                       | no       | `false`                                                                                |
| security_rules                        | list(object) | The security rules to use for the VM                                                             | no       | `[]`                                                                                   |
| security_rules.name                   | string       | Name of the security rule                                                                        | yes      |                                                                                        |
| security_rules.description            | string       | Description of the security rule                                                                 | no       | `""`                                                                                   |
| security_rules.direction              | string       | Direction of the security rule                                                                   | no       | `"Inbound"`                                                                            |
| security_rules.access                 | string       | Access of the security rule                                                                      | no       | `"Allow"`                                                                              |
| security_rules.priority               | number       | Priority of the security rule                                                                    | yes      |                                                                                        |
| security_rules.protocol               | string       | Protocol of the security rule                                                                    | no       | `"Tcp"`                                                                                |
| security_rules.source_port_range      | string       | Source port range of the security rule                                                           | no       | `"*"`                                                                                  |
| security_rules.source_address_prefix  | string       | Source address prefix of the security rule                                                       | no       | `"*"`                                                                                  |
| security_rules.destination_port_range | string       | Destination port range of the security rule                                                      | yes      |                                                                                        |
| tags                                  | map(string)  | Map of tags to assign to the resources                                                           | no       | `{}`                                                                                   |

##### Outputs

| Output                    | Type   | Description                        |
| ------------------------- | ------ | ---------------------------------- |
| public_ip                 | string | Public ip if enabled               |
| network_name              | string | Name of the network                |
| subnet_id                 | string | Id of the subnet                   |
| network_security_group_id | string | Id of the network security group   |
| vm_username               | string | Admin username                     |
| vm_id                     | string | Id of the VM                       |
| nsg_name                  | string | Name of the network security group |

#### Container Instances

```hcl
module "container-instances" {
  source = "github.com/THEY-Consulting/they-terraform//azure/container-instances"

  name                = "they-test-container-instances"
  resource_group_name = "they-terraform-test"
  create_new_resource_group = true
  location            = "Germany West Central"
  enable_log_analytics = true
  registry_credential = {
    server   = "test.azurecr.io"
    username = "User"
    password = "PassworD"
  }
  dns_a_record_name = "dns_name"
  dns_resource_group = "they-dev"
  dns_record_ttl = 400
  dns_zone_name = "dns-zone.com"
  exposed_port = [{
      port     = 3000
      protocol = "TCP"
    },{
      port     = 80
      protocol = "TCP"
    }
    ]
  tags = {
    environment = "test"
  }
  containers = [
  {
    name   = "frontend-test"
    image  = "test.azurecr.io/frontend-test:latest"
    cpu    = "2"
    memory = "4"
    environment_variables = {
      ENV1_API_URL= "https://localhost:80/api"
      ENV2   = "demo"
    }
    ports  = {
      port     = 3000
      protocol = "TCP"
    }

  },
  {
    name   = "backend-test"
    image  = "test.azurecr.io/backend-test:latest"
    cpu    = "1"
    memory = "2"
    environment_variables = {
      ENV1 = "test"
    }
    ports  = {
      port     = 80
      protocol = "TCP"
    },
    liveness_probe = {
      http_get = {
        path = "/health"
        port = 80
      }
      initial_delay_seconds = 100
      period_seconds      = 5
      failure_threshold = 3
      success_threshold = 1
    }
  }
]
}
```

##### Inputs

| Variable                         | Type         | Description                                                                                                                                                                  | Required | Default     |
| -------------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------- |
| name                             | string       | Name of the resources                                                                                                                                                        | yes      |             |
| resource_group_name              | string       | The name of the resource group in which to create the resources                                                                                                              | yes      |             |
| create_new_resource_group        | bool         | If true, a new resource group with the name `resource_group_name` will be created. Otherwise the deployment will use an existing resource group named `resource_group_name`. | no       | `false`     |
| dns_resource_group               | string       | Resource group where the DNS zone is located                                                                                                                                 | no       | `null`      |
| dns_a_record_name                | string       | The name of the DNS A record                                                                                                                                                 | no       | `null`      |
| dns_zone_name                    | string       | The name of the DNS zone                                                                                                                                                     | no       | `null`      |
| dns_record_ttl                   | number       | The TTL of the DNS record                                                                                                                                                    | no       | `300`       |
| location                         | string       | The Azure region where the resources should be created                                                                                                                       | yes      |             |
| enable_log_analytics             | bool         | Enables the creation of the resource log analytics workspace for the container group                                                                                         | no       | `false`     |
| sku_log_analytics                | string       | The SKU of the log analytics workspace                                                                                                                                       | no       | `PerGB2018` |
| log_retention                    | number       | The number of days to retain logs in the log analytics workspace                                                                                                             | no       | `30`        |
| registry_credential              | object       | The credentials for the container registry                                                                                                                                   | no       | `null`      |
| ip_address_type                  | string       | The type of IP address that should be used                                                                                                                                   | yes      | `Public`    |
| os_type                          | string       | The os type that should be used                                                                                                                                              | yes      | `Linux`     |
| exposed_port                     | list(object) | The list of ports that should be exposed                                                                                                                                     | no       | `[]`        |
| containers.name                  | string       | Name of the container                                                                                                                                                        | yes      |             |
| containers.image                 | string       | Image of the container                                                                                                                                                       | yes      |             |
| containers.cpu                   | string       | The required number of CPU cores of the containers                                                                                                                           | yes      |             |
| containers.memory                | string       | The required memory of the containers in GB                                                                                                                                  | yes      |             |
| containers.environment_variables | map(string)  | A list of environment variables to be set on the container                                                                                                                   | no       |             |
| containers.ports                 | object       | A set of public ports for the container                                                                                                                                      | no       |             |
| containers.liveness_probe        | object       | The definition of a liveness probe for this container                                                                                                                        | no       |             |
| containers.readiness_probe       | object       | The definition of a readiness probe for this container                                                                                                                       | no       |             |
| tags                             | map(string)  | Map of tags to assign to the resources                                                                                                                                       | no       | `{}`        |

##### Outputs

| Output             | Type   | Description                                                            |
| ------------------ | ------ | ---------------------------------------------------------------------- |
| container_endpoint | string | Endpoint of the container. It gives a public IP if no DNS is indicated |

#### Container Apps

```hcl
module "container-apps" {
  source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"

  name                      = "they-test-container-apps"
  location                  = "Germany West Central"
  create_new_resource_group = true
  resource_group_name       = "they-test-container-apps"
  workload_profile = {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
  unique_environment_certificate = {
    key_vault_secret_name = "my-cert-secret-name"
    name                  = "app-env-cert"
  }
  enable_log_analytics = true
  is_system_assigned = true
  dns_zone = {
    existing_dns_zone_name                = "they-azure.de"
    existing_dns_zone_resource_group_name = "they-dev"
  }
  container_apps = {
    backend = {
      name          = "backend"
      revision_mode = "Single"
      subdomain     = "test-backend"
      cors_enabled          = true
      cors_allowed_origins  = "https://my-allowed-origin.com"
      ingress = {
        allow_insecure_connections = true
        external_enabled           = true
        target_port                = 81
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      registry = [{
        server               = "test.azurecr.io"
        username             = "User"
        password_secret_name = "registry-secret"
      }]
      secret = {
        name  = "registry-secret"
        value = "Password"
      }
      template = {
        max_replicas = 3
        min_replicas = 1
        containers = [
          {
            name   = "backend-test"
            image  = "test.azurecr.io/backend-test:latest"
            cpu    = "0.5"
            memory = "1.0Gi"
          }
        ]
      }
    },
    frontend = {
      name          = "frontend"
      revision_mode = "Single"
      subdomain     = "test-frontend"
      ingress = {
        allow_insecure_connections = true
        external_enabled           = true
        target_port                = 3000
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      registry = [{
        server               = "test.azurecr.io"
        username             = "Username"
        password_secret_name = "registry-secret"
      }]
      secret = {
        name  = "registry-secret"
        value = "Password"
      }
      template = {
        max_replicas = 3
        min_replicas = 1
        containers = [
          {
            name   = "frontend-test"
            image  = "test.azurecr.io/frontend-test:latest"
            cpu    = "2.0"
            memory = "4.0Gi"
            env = [
              {
                name  = "ENV_BASE_URL"
                value = "http://example.com"
              },
              {
                name  = "ENV_2"
                value = "ANOTHER_ENV_VAR_VALUE"
              }
            ]
          }
        ]
      }
    }
  }
}
```

##### Inputs

| Variable                             | Type         | Description                                                                                                                                                                                       | Required | Default      |
| ------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------ |
| name                                 | string       | Name of project. It will also be the name of the resource group, if a resource group is to be created.                                                                                            | yes      |              |
| resource_group_name                  | string       | The name of the resource group in which to create the resources                                                                                                                                   | yes      |              |
| key_vault_name                       | string       | The name of the key vault that has the certificates and secrets of each container app.                                                                                                            | no       | `null`       |
| key_vault_resource_group_name        | string       | The name of the resource group where the key vault is                                                                                                                                             | no       | `null`       |
| workload_profile                     | object       | An object that defines the workload profile of the environment. Leaving its default value means having a managed environment `Consumption Only`                                                   | no       | `null`       |
| is_system_assigned                   | bool         | It defines whether a system-assigned managed identity will be created.                                                                                                                            | no       | `false`      |
| unique_environment_certificate       | object       | If only one certificate is used in the environment for all the container apps, this is the variable to fill. In this case, the variable `container_apps.key_vault_secret_name` must be left blank | no       | `null`       |
| location                             | string       | The Azure Region where the resource should be created                                                                                                                                             | yes      |              |
| container_registry_server            | string       | The server URL of the container.                                                                                                                                                                  | no       | `null`       |
| dns_zone                             | object       | DNS zone config required if you want to link the deployed app to a subdomain in the given dns zone. Does not create a dns zone, only a subdomain.                                                 | no       | `null`       |
| dns_record_ttl                       | number       | The TTL of the DNS record                                                                                                                                                                         | no       | `300`        |
| certificate_binding_type             | string       | The Certificate binding type.                                                                                                                                                                     | no       | `SniEnabled` |
| enable_log_analytics                 | bool         | Enables the creation of the resource log analytics workspace for the container group                                                                                                              | no       | `false`      |
| sku_log_analytics                    | string       | The SKU of the log analytics workspace                                                                                                                                                            | no       | `PerGB2018`  |
| container_apps                       | map(object)  | The container apps to deploy                                                                                                                                                                      | yes      |              |
| container_apps.name                  | string       | Name of the container app                                                                                                                                                                         | yes      |              |
| container_app.subdomain              | string       | subdomain for the container                                                                                                                                                                       | no       |              |
| container_apps.tags                  | map(string)  | A mapping of tags to assign to the Container App.                                                                                                                                                 | no       |              |
| container_apps.revision_mode         | string       | The revisions operational mode for the Container App. Possible values include Single and Multiple. In Single mode, a single revision is in operation at any given time.                           | yes      |              |
| container_apps.workload_profile_name | string       | The name of the Workload Profile in the Container App Environment to place this Container App.                                                                                                    | no       |              |
| container_apps.cors_enabled          | bool         | Attribute to indicate if cors must be enabled                                                                                                                                                     | no       |              |
| container_apps.cors_allowed_origins  | string       | The URL origins allowed.                                                                                                                                                                          | no       |              |
| container_apps.key_vault_secret_name | string       | The secret name of the certificate for the container app. NOTE: All certificates must be in the same key vault (see var above)                                                                    | no       |              |
| container_apps.template              | object       | A template block.                                                                                                                                                                                 | yes      |              |
| container_apps.ingress               | object       | Ingress block                                                                                                                                                                                     | no       |              |
| container_apps.identity              | object       | Identity block that supports `type` and `identity_ids` as attributes.                                                                                                                             | no       |              |
| container_apps.secret                | object       | Secret block                                                                                                                                                                                      | no       |              |
| container_apps.registry              | list(object) | The credentials and information needed to connect to a container registry                                                                                                                         | no       |              |

##### Outputs

| Output              | Type   | Description                                                                                                                                                                      |
| ------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| container_apps_urls | string | URLs of the container apps. If a custom domain was used, this will be the ouput. Otherwise, the FQDN of the latest revision of each respective Container App will be the output. |

#### Storage Container

```hcl
module "storage_container" {
  source = "github.com/THEY-Consulting/they-terraform//azure/storage-container"

  name                = "they-storage-container"
  resource_group_name = "they-dev"
  location            = "Germany West Central"

  container_access_type = "private"
  metadata = {
    environment = "dev"
    department  = "it"
  }

  storage_account = {
    # name = "customstorageaccount" # Optional: Automatically generated from container name if not specified
    preexisting_name = null # If null, a new storage account will be created
    tier             = "Standard"
    replication_type = "LRS"
    kind             = "StorageV2"
    access_tier      = "Hot"
    is_hns_enabled = false

    # CORS configuration
    cors_rules = [
      {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "POST", "PUT"]
        allowed_origins = ["https://myapp.example.com"]
        exposed_headers = ["*"]
        max_age_in_seconds = 3600
      }
    ]
  }

  enable_static_website = true

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}
```

##### Inputs

| Variable                                        | Type         | Description                                                                  | Required | Default        |
|-------------------------------------------------|--------------|------------------------------------------------------------------------------|----------|----------------|
| name                                            | string       | Name of the storage container                                                | yes      |                |
| resource_group_name                             | string       | The name of the resource group in which to create the resources              | yes      |                |
| location                                        | string       | The Azure region where the resources should be created                       | yes      |                |
| container_access_type                           | string       | The access type for the container. Possible values: blob, container, private | no       | `"private"`    |
| metadata                                        | map(string)  | A mapping of metadata to assign to the storage container                     | no       | `{}`           |
| storage_account                                 | object       | The storage account configuration                                            | no       | see sub fields |
| storage_account.preexisting_name                | string       | Name of an existing storage account; if null, a new one will be created      | no       | `null`         |
| storage_account.preexisting_resource_group_name | string       | Resource group name of the existing storage account                          | no       | `null`         |
| storage_account.name                            | string       | Name for the new storage account; if null, derived from container name       | no       | `null`         |
| storage_account.tier                            | string       | Tier of the storage account (Standard or Premium)                            | no       | `"Standard"`   |
| storage_account.replication_type                | string       | Replication type for the storage account                                     | no       | `"LRS"`        |
| storage_account.kind                            | string       | Kind of storage account                                                      | no       | `"StorageV2"`  |
| storage_account.access_tier                     | string       | Access tier for the storage account (Hot or Cool)                            | no       | `"Hot"`        |
| storage_account.is_hns_enabled                  | bool         | Enable hierarchical namespace (required for Data Lake Gen2)                  | no       | `false`        |
| storage_account.min_tls_version                 | string       | Minimum TLS version                                                          | no       | `"TLS1_2"`     |
| storage_account.cors_rules                      | list(object) | List of CORS rules for the storage account                                   | no       | `null`         |
| enable_static_website                           | bool         | Enable or disable the static website feature for the storage account         | no       | `false`        |
| tags                                            | map(string)  | Tags for the resources                                                       | no       | `{}`           |

##### Outputs

| Output                    | Type   | Description                                           |
|---------------------------|--------|-------------------------------------------------------|
| id                        | string | The ID of the storage container                       |
| name                      | string | The name of the storage container                     |
| storage_account_name      | string | The name of the storage account                       |
| storage_account_id        | string | The ID of the storage account                         |
| primary_access_key        | string | The primary access key for the storage account        |
| primary_connection_string | string | The primary connection string for the storage account |
| container_url             | string | The URL of the storage container                      |

#### Datadog Diagnostics

```hcl
module "diagnostics" {
  source = "github.com/THEY-Consulting/they-terraform//azure/monitoring/datadog"

  environment             = "dev"
  eventhub_namespace_name = "they-test"
  handler_name            = "datadog-importer-they-test"
  location                = "Germany West Central"
  resource_group_name     = "they-dev"

  sku      = "Basic"
  capacity = 1
  
  dd_api_key = "datadog-api-key"
  dd_site    = "datadoghq.eu"
  dd_service = "they-diagnostics"
  dd_tags    = "they,diagnostics"

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}
```

##### Inputs

| Variable                | Type        | Description                                                                                           | Required | Default          |
|-------------------------|-------------|-------------------------------------------------------------------------------------------------------|----------|------------------|
| environment             | string      | Name of project. It will also be the name of the resource group, if a resource group is to be created | no       | `"dev"`          |
| eventhub_namespace_name | string      | Name of the eventhub namespace                                                                        | yes      |                  |
| handler_name            | string      | Name of the logs handler                                                                              | yes      |                  |
| location                | string      | The Azure Region where the resource should be created                                                 | yes      |                  |
| resource_group_name     | string      | The name of the resource group in which to create the resources                                       | yes      |                  |
| sku                     | string      | The SKU of the event hubs namespace. This is the pricing tier. Use 'Basic', 'Standard', or 'Premium'  | no       | `"Basic"`        |
| capacity                | number      | The capacity of the event hubs namespace. This is the number of throughput units                      | no       | `1`              |
| dd_api_key              | string      | Datadog API key                                                                                       | yes      |                  |
| dd_site                 | string      | Datadog site                                                                                          | no       | `"datadoghq.eu"` |
| dd_service              | string      | Sets the service name within datadog                                                                  | no       | `""`             |
| dd_tags                 | string      | Comma-separated list of tags to send to datadog                                                       | no       | `""`             |
| tags                    | map(string) | Map of tags to assign to the resources                                                                | no       | `{}`             |

##### Outputs

| Output                                        | Type   | Description                                                                                                   |
|-----------------------------------------------|--------|---------------------------------------------------------------------------------------------------------------|
| diagnostics                                   | object | Contains information about the event hub, can be used as `diagnostics` parameter of the azure function module |
| diagnostics.eventhub_name                     | string | Name of the event hub                                                                                         |
| diagnostics.namespace                         | string | Name of the event hub namespace                                                                               |
| diagnostics.namespace_authorization_rule_name | string | Name of the authorization rule that allows produces to send logs to the event hub                             |

#### Front Door

```hcl
#### Front Door
# Create a shared Front Door profile (optional)
resource "azurerm_cdn_frontdoor_profile" "shared_profile" {
  name                     = "shared-frontdoor-profile"
  resource_group_name      = "my-resource-group"
  response_timeout_seconds = 16
  sku_name                 = "Standard_AzureFrontDoor"
}

# Web example (static website hosting)
module "frontdoor_web" {
  source = "github.com/THEY-Consulting/they-terraform//azure/frontdoor"

  resource_group = {
    name     = "my-resource-group"
    location = "Germany West Central"
  }

  # Optional: Use shared profile instead of creating a new one
  frontdoor_profile = {
    id   = azurerm_cdn_frontdoor_profile.shared_profile.id
    name = azurerm_cdn_frontdoor_profile.shared_profile.name
  }

  # Web-specific configuration for static website hosting
  web = {
    primary_web_host = "mystorageaccount.z6.web.core.windows.net"
  }

  # Domain configuration
  domain    = "example"
  subdomain = "www"
  
  # DNS zone configuration - if you have an existing DNS zone
  dns_zone_name           = "example.com"
  dns_zone_resource_group = "my-dns-resource-group"
  is_external_dns_zone    = false
  
  # Cache settings (optional)
  cache_settings = {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/css", "application/javascript"]
  }
}

# Backend API example
module "frontdoor_backend" {
  source = "github.com/THEY-Consulting/they-terraform//azure/frontdoor"

  resource_group = {
    name     = "my-resource-group"
    location = "Germany West Central"
  }

  # Optional: Use shared profile instead of creating a new one
  frontdoor_profile = {
    id   = azurerm_cdn_frontdoor_profile.shared_profile.id
    name = azurerm_cdn_frontdoor_profile.shared_profile.name
  }

  # Backend-specific configuration for APIs
  backend = {
    host                          = "10.0.0.1"  # VM public IP or other backend host
    host_header                   = "api.example.com"
    certificate_name_check_enabled = false
    forwarding_protocol           = "HttpOnly"
    http_port                     = 80
    https_port                    = 443
    health_probe = {
      path         = "/health"
      interval     = 120
      protocol     = "Http"
      request_type = "GET"
    }
  }

  # Domain configuration
  domain    = "example"
  subdomain = "api"
  
  # DNS zone configuration
  dns_zone_name           = "example.com"
  dns_zone_resource_group = "my-dns-resource-group"
  
  # Cache settings for API (minimal caching)
  cache_settings = {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["application/json", "text/plain"]
  }
}
```

##### Inputs

| Variable                                     | Type         | Description                                                                                                                                                       | Required | Default                                                                               |
|----------------------------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------------------------------------------------------------------------------------|
| resource_group                               | object       | The resource group where the Front Door resources will be created                                                                                                 | yes      |                                                                                       |
| resource_group.name                          | string       | The name of the resource group                                                                                                                                    | yes      |                                                                                       |
| resource_group.location                      | string       | The location of the resource group                                                                                                                                | yes      |                                                                                       |
| frontdoor_profile                            | object       | Existing Front Door profile to use instead of creating a new one                                                                                                  | no       | `null`                                                                                |
| frontdoor_profile.id                         | string       | The ID of the existing Front Door profile                                                                                                                         | (yes)    |                                                                                       |
| frontdoor_profile.name                       | string       | The name of the existing Front Door profile                                                                                                                       | (yes)    |                                                                                       |
| web                                          | object       | Configuration for web/frontend usage with storage account. Use this for static website hosting                                                                    | no*      | `null`                                                                                |
| web.primary_web_host                         | string       | Primary web host of the storage account                                                                                                                           | (yes)    |                                                                                       |
| backend                                      | object       | Configuration for backend API services                                                                                                                            | no*      | `null`                                                                                |
| backend.host                                 | string       | Backend host (VM IP, App Service, etc.)                                                                                                                           | (yes)    |                                                                                       |
| backend.host_header                          | string       | Host header to send to the backend                                                                                                                                | no       | Value of backend.host                                                                 |
| backend.certificate_name_check_enabled       | bool         | Whether to check the certificate name                                                                                                                             | no       | `false`                                                                               |
| backend.forwarding_protocol                  | string       | Protocol to use when forwarding requests to the backend                                                                                                           | no       | `"HttpOnly"`                                                                          |
| backend.http_port                            | number       | HTTP port for the backend                                                                                                                                         | no       | `80`                                                                                  |
| backend.https_port                           | number       | HTTPS port for the backend                                                                                                                                        | no       | `443`                                                                                 |
| backend.health_probe                         | object       | Health probe configuration for the backend                                                                                                                        | no       | `{ path = "/", interval = 120, protocol = "Http", request_type = "GET" }`             |
| storage_account.primary_web_host             | string       | Primary web host of the storage account                                                                                                                           | (yes)    |                                                                                       |
| domain                                       | string       | The base domain name (without the subdomain part)                                                                                                                 | yes      |                                                                                       |
| subdomain                                    | string       | The subdomain to use (e.g., 'www' for www.example.com)                                                                                                            | no       | `"www"`                                                                               |
| dns_zone_name                                | string       | The name of the DNS zone where the CNAME and TXT validation records will be created                                                                               | no       | `null`                                                                                |
| dns_zone_resource_group                      | string       | The resource group containing the DNS zone. Defaults to the same resource group as the Front Door                                                                 | no       | `null`                                                                                |
| is_external_dns_zone                         | bool         | Set to true if the domain is managed outside of the Azure account (e.g., in AWS Route 53 or in another Azure account). If true, DNS records will not be created.  | no       | `false`                                                                               |
| cache_settings                               | object       | Cache settings for the Front Door                                                                                                                                 | no       | `{ query_string_caching_behavior = "IgnoreQueryString", compression_enabled = true }` |
| cache_settings.query_string_caching_behavior | string       | Query string caching behavior                                                                                                                                     | no       | `"IgnoreQueryString"`                                                                 |
| cache_settings.compression_enabled           | bool         | Whether compression is enabled                                                                                                                                    | no       | `true`                                                                                |
| cache_settings.content_types_to_compress     | list(string) | Content types to compress                                                                                                                                         | no       | `["application/json", "text/plain", "text/css", "application/javascript"]`            |

*You must provide exactly one of `web` or `backend`

##### Outputs

| Output                         | Type   | Description                                |
|--------------------------------|--------|--------------------------------------------|
| endpoint_url                   | string | The URL of the Front Door endpoint         |
| custom_domain_url              | string | The URL of the custom domain               |
| cdn_frontdoor_profile_id       | string | The ID of the Front Door profile           |
| cdn_frontdoor_name             | string | The name of the Front Door profile         |
| cdn_frontdoor_endpoint_id      | string | The ID of the Front Door endpoint          |
| cdn_frontdoor_endpoint_name    | string | The name of the Front Door endpoint        |
| custom_domain_validation_token | string | The validation token for the custom domain |
| endpoint_host_name             | string | The host name of the Front Door endpoint   |
| route_id                       | string | The ID of the Front Door route             |
| route                          | object | The Front Door route resource              |

#### Frontdoor Domain

```hcl
module "frontdoor_domain" {
  source = "github.com/THEY-Consulting/they-terraform//azure/frontdoor-domain"

  resource_group_name = "they-dev"
  dns_zone_name       = "they-azure.de"
  subdomain           = "www"
  frontdoor_host_name = module.frontdoor_web.endpoint_host_name
  validation_token    = module.frontdoor_web.custom_domain_validation_token
}
```


##### Inputs

| Variable            | Type   | Description                                                                         | Required | Default |
|---------------------|--------|-------------------------------------------------------------------------------------|----------|---------|
| subdomain           | string | The subdomain to use (e.g., 'www' for www.yourdomain.com)                           | no       | `"www"` |
| dns_zone_name       | string | The name of the DNS zone where the CNAME and TXT validation records will be created | yes      |         |
| resource_group_name | string | The resource group containing the DNS zone                                          | yes      |         |
| validation_token    | string | The validation token for the custom domain                                          | yes      |         |
| frontdoor_host_name | string | The host name of the Azure Front Door endpoint                                      | yes      |         |


##### Outputs

This module does not have any outputs.

#### Container Registry

```hcl
module "container_registry" {
  source = "github.com/THEY-Consulting/they-terraform//azure/container-registry"

  name = "theyregistry"
  resource_group = {
    name     = "they-dev"
    location = "Germany West Central"
  }

  # Basic configuration
  sku           = "Standard"  # Options: Basic, Standard, Premium
  admin_enabled = true        # Enable admin for simple authentication

  # Premium SKU features
  retention_policy_days     = 30      # Days to retain untagged manifests
  quarantine_policy_enabled = true    # Enable quarantine for uploaded images
  trust_policy_enabled      = true    # Enable content trust
  export_policy_enabled     = true    # Enable export of registry data
  
  # Features for Standard and Premium SKUs
  anonymous_pull_enabled = false      # Require authentication for pulls
  
  # More Premium SKU features
  data_endpoint_enabled         = true              # Enable dedicated data endpoints
  network_rule_bypass_option    = "AzureServices"   # Allow Azure services to access 
  public_network_access_enabled = true
  zone_redundancy_enabled       = true              # Enable multi-zone redundancy
  
  # Geo-replication for disaster recovery (Premium SKU only)
  geo_replications = [
    {
      location                  = "West Europe"
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = true
      tags                      = { replica = "west-europe" }
    }
  ]

  # Network access rules (Premium SKU only)
  network_rule_set = {
    default_action = "Deny"                               # Deny all by default
    ip_rules       = ["203.0.113.0/24", "198.51.100.10"]  # Allow specific IPs
  }

  # Managed identity for registry authentication
  identity = {
    type         = "SystemAssigned"   # System-assigned managed identity
    identity_ids = null               # Used for user-assigned identities
  }

  # Customer-managed keys for encryption
  # Note: Requires a key vault and managed identity
  encryption = {
    key_vault_key_id   = "https://my-keyvault.vault.azure.net/keys/mykey/version"
    identity_client_id = "00000000-0000-0000-0000-000000000000"
  }

  tags = {
    Project     = "they-project"
    CreatedBy   = "terraform"
    Environment = "dev"
  }
}
```

##### Inputs

| Variable                      | Type         | Description                                                                                            | Required | Default           |
|-------------------------------|--------------|--------------------------------------------------------------------------------------------------------|----------|-------------------|
| name                          | string       | Name of the container registry                                                                         | yes      |                   |
| resource_group                | object       | The resource group where the registry will be created                                                  | yes      |                   |
| resource_group.name           | string       | Name of the resource group                                                                             | yes      |                   |
| resource_group.location       | string       | Location of the resource group                                                                         | yes      |                   |
| sku                           | string       | The SKU of the container registry. Possible values are 'Basic', 'Standard', and 'Premium'              | no       | `"Standard"`      |
| admin_enabled                 | bool         | Specifies whether the admin user is enabled                                                            | no       | `false`           |
| retention_policy_days         | number       | The number of days to retain an untagged manifest. Only available for Premium SKU                      | no       | `7`               |
| quarantine_policy_enabled     | bool         | Boolean value that indicates whether quarantine policy is enabled. Only available for Premium SKU      | no       | `false`           |
| trust_policy_enabled          | bool         | Boolean value that indicates whether the trust policy is enabled. Only available for Premium SKU       | no       | `false`           |
| export_policy_enabled         | bool         | Boolean value that indicates whether the export policy is enabled. Only available for Premium SKU      | no       | `true`            |
| anonymous_pull_enabled        | bool         | Whether to allow anonymous pull access. Only available for Standard and Premium SKUs                   | no       | `false`           |
| data_endpoint_enabled         | bool         | Whether to enable dedicated data endpoints for this Container Registry. Only available for Premium SKU | no       | `false`           |
| network_rule_bypass_option    | string       | Whether to allow trusted Azure services to access a network restricted Container Registry              | no       | `"AzureServices"` |
| geo_replications              | list(object) | A list of Azure locations where the container registry should be geo-replicated. Only for Premium SKU  | no       | `[]`              |
| network_rule_set              | object       | Network rules for the container registry. Only available for Premium SKU                               | no       | `null`            |
| public_network_access_enabled | bool         | Whether public network access is allowed for the container registry                                    | no       | `true`            |
| zone_redundancy_enabled       | bool         | Whether zone redundancy is enabled for the container registry                                          | no       | `false`           |
| identity                      | object       | The type of identity to use for the container registry                                                 | no       | `null`            |
| encryption                    | object       | Encryption settings for the container registry                                                         | no       | `null`            |
| tags                          | map(string)  | Tags for the resources                                                                                 | no       | `{}`              |

##### Outputs

| Output            | Type   | Description                                                                                  |
|-------------------|--------|----------------------------------------------------------------------------------------------|
| id                | string | The ID of the Container Registry                                                             |
| name              | string | The name of the Container Registry                                                           |
| login_server      | string | The URL that can be used to log into the container registry                                  |
| admin_username    | string | The Username associated with the Container Registry Admin account - if admin is enabled      |
| admin_password    | string | The Password associated with the Container Registry Admin account - if admin is enabled      |
| identity          | object | The identity of the Container Registry                                                       |

## Contributing

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) version 1.6.4
- [tfenv](https://github.com/tfutils/tfenv) optional, recommended
- [nodejs](https://nodejs.org/en) version 18.X
- [yarn](https://classic.yarnpkg.com/lang/en/docs/) `npm i -g yarn`
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [direnv](https://direnv.net/)

### Environment Variables

- Configure your environment variables (create and put them in `.envrc` in the project's root dir):

```bash
export AWS_PROFILE=nameOfProfile
export AZURE_TENANT_ID=tenantId #<see https://portal.azure.com/#settings/directory for the correct Directory ID>
export TF_VAR_tenant_id=$AZURE_TENANT_ID

```

- Remember to add the aws profile info to `~/.aws/config`
- And the key and secret for said profile to `~/.aws/credentials`

### Local Dev

Install dependencies:

```bash
cd examples/aws/.packages
yarn install

cd examples/azure/.packages
yarn install
```

If you want to import and test changes you made without merging them first into main,
you can use the git commit hash as the version in the source URL
when importing the module within other projects.
Don't forget to remove the hash when you are done ;)

```hcl
module "module_with_unmerged_changes" {
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda?ref=ee423515"
}
```

### Deployment

Currently, we only use a single workspace within each cloud provider.
To deploy each example execute:

```bash
cd examples/aws/<example>
terraform apply

cd examples/azure/<example>
terraform apply
```

The resources used to manage the state of the resources deployed within the `examples` folder can be found at `examples/.setup-tfstate`.
If you want to set up your own Terraform state management system, remove any `.terraform.lock.hcl` files within the `examples` folder, and deploy the resources at `examples/.setup-tfstate/` in your own AWS account.

#### Clean-up

When you are done testing, please destroy the resources with `terraform destroy`.

`examples/aws/setup-tfstate` is a bit more complicated to clean up.
`terraform destroy` can not remove the S3 bucket (due to `prevent_destroy = true`).

Therefore, you need to delete the bucket manually in the AWS console.
After that you can remove the remaining resources with `terraform destroy`.
Keep in mind that after destroying a bucket it can take up to 24 hours until the name is available again.

`
