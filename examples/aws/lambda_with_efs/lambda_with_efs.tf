# --- RESOURCES / MODULES ---

module "lambda_with_efs" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "${terraform.workspace}-they-test-lambda-efs"
  description = "Lambda with EFS integration"
  source_dir  = "../.packages/lambda-efs"
  runtime     = "nodejs20.x"
  is_bundle   = true
  vpc_config = {
    subnet_ids         = [aws_subnet.public.id]
    security_group_ids = [aws_security_group.lambda.id]
  }
  mount_efs = aws_efs_access_point.lambda.arn
  iam_policy = [{
    name = "efs-access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeMountTargets"
        ],
        "Resource" : aws_efs_file_system.main.arn
      }]
    })
  }]
}

# --- OUTPUT ---

output "build" {
  value = module.lambda_with_efs.build
}
