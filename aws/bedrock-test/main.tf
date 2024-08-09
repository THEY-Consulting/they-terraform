data "aws_caller_identity" "this" {}
data "aws_partition" "this" {}
data "aws_region" "this" {}

resource "aws_iam_role" "bedrock_kb" {
  name = "AmazonBedrockExecutionRoleForKnowledgeBase_TEST"
  path               = "/service-role/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AmazonBedrockKnowledgeBaseTrustPolicy",
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.this.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.this.partition}:bedrock:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "bedrock_kb_model" {
  name = "AmazonBedrockFoundationModelPolicyForKnowledgeBase_TEST"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = [
          "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
          "arn:aws:bedrock:eu-central-1::foundation-model/amazon.titan-embed-text-v1"
        ]
      }
    ]
  })
}


resource "aws_iam_policy" "bedrock_kb_oss" {
  name = "AmazonBedrockOSSPolicyForKnowledgeBase_TEST"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "aoss:APIAccessAll"
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.example.arn
      }
    ]
  })
}

resource "aws_iam_policy" "bedrock_kb_s3" {
  name = "AmazonBedrockS3PolicyForKnowledgeBase_TEST"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListBucketStatement"
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::your-knowledge-bucket"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.this.account_id
          }
      } },
      {
        Sid      = "S3GetObjectStatement"
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::your-knowledge-bucket/*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.this.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kb_oss" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.bedrock_kb_oss.arn
}

resource "aws_iam_role_policy_attachment" "kb_model" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.bedrock_kb_model.arn
}

resource "aws_iam_role_policy_attachment" "lb_s3" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.bedrock_kb_s3.arn
}


resource "aws_opensearchserverless_access_policy" "example" {
  name        = "example"
  type        = "data"
  description = "read and write permissions"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/open-search-collection/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/open-search-collection"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.this.arn,
        aws_iam_role.bedrock_kb.arn
      ]
    }
  ])
}


resource "aws_opensearchserverless_security_policy" "example-encryption" {
  name = "example-encryption"
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/open-search-collection"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_security_policy" "example-network" {
  name = "example-network"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/open-search-collection"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/open-search-collection"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_collection" "example" {
  name = "open-search-collection"
  type = "VECTORSEARCH"
  depends_on = [aws_opensearchserverless_security_policy.example-encryption, aws_opensearchserverless_security_policy.example-network]
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.example.collection_endpoint
  healthcheck = false
}

resource "opensearch_index" "opensearch_index" {
  name                           = "bedrock-knowledge-base-default-index"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1536,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [aws_opensearchserverless_collection.example]
}

resource "time_sleep" "timer1" {
  create_duration = "150s"
  depends_on      = [aws_iam_policy.bedrock_kb_oss, aws_iam_role_policy_attachment.kb_oss, aws_iam_role_policy_attachment.kb_model, aws_iam_role_policy_attachment.lb_s3]
}

resource "aws_bedrockagent_knowledge_base" "example" {
  name     = "test-example"
  role_arn = aws_iam_role.bedrock_kb.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:eu-central-1::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.example.arn 
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    aws_iam_policy.bedrock_kb_model,
    aws_iam_policy.bedrock_kb_s3,
    opensearch_index.opensearch_index,
    time_sleep.timer1
  ]
}

resource "aws_bedrockagent_data_source" "example" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.example.id
  name              = "test-example-core-api"


  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = "arn:aws:s3:::your-knowledge-bucket"
    }
  }
}