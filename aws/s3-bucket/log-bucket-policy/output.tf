data "aws_region" "current" {}
data "aws_elb_service_account" "main" {}

output "policies" {
  value = [
    {
      Effect = "Allow"
      Principal = {
        AWS = [data.aws_elb_service_account.main.arn]
      }
      Action   = ["s3:PutObject"]
      Resource = "arn:aws:s3:::${var.bucket_name}/*",
    },
    {
      Effect = "Allow"
      Principal = {
        Service = ["delivery.logs.amazonaws.com"]
      }
      Action   = ["s3:PutObject"]
      Resource = "arn:aws:s3:::${var.bucket_name}/*",
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
    },
    {
      Effect = "Allow"
      Principal = {
        Service = ["delivery.logs.amazonaws.com"]
      }
      Action   = ["s3:GetBucketAcl"]
      Resource = "arn:aws:s3:::${var.bucket_name}",
    },
    {
      Effect = "Allow"
      Principal = {
        Service = ["logs.${data.aws_region.current.name}.amazonaws.com"]
      }
      Action   = ["s3:GetBucketAcl"]
      Resource = "arn:aws:s3:::${var.bucket_name}",
    },
    {
      Effect = "Allow"
      Principal = {
        Service = ["logs.${data.aws_region.current.name}.amazonaws.com"]
      }
      Action   = ["s3:PutObject"]
      Resource = "arn:aws:s3:::${var.bucket_name}/*",
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
    }
  ]
}
