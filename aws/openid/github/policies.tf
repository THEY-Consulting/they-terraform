locals {
  prepared_policies = [for policy in [
    (var.s3StateBackend && var.include_default_policies.s3StateBackend) ? {
      name = "TerraformStateAccess"
      policy = jsonencode({
        Version : "2012-10-17",
        Statement : local.tfstate_statements,
    }) } : null,

    var.include_default_policies.cloudfront ? {
      name : "Cloudfront"
      policy : jsonencode({
        Version : "2012-10-17",
        Statement : local.cloudfront_statements,
      }),
    } : null,

    var.include_default_policies.cloudwatch ? {
      name : "CloudWatch"
      policy : jsonencode({
        Version : "2012-10-17",
        Statement : local.cloudwatch_statements
      }),
    } : null,

    var.include_default_policies.asg ? {
      name : "EC2"
      policy : jsonencode({
        Version : "2012-10-17",
        Statement : local.ec2_statements,
      })
    } : null,

    var.include_default_policies.asg ? {
      name : "ELB"
      policy : jsonencode({
        Version : "2012-10-17",
        Statement : local.elb_statements,
      })
    } : null,

    var.include_default_policies.asg ? {
      name : "ASG"
      policy : jsonencode({
        Version : "2012-10-17",
        Statement : local.asg_statements,
      })
    } : null,

    (var.include_default_policies.asg || var.include_default_policies.iam) ? {
      name : "IAM"
      policy : jsonencode({
        Version : "2012-10-17",
        Statement : local.iam_statements,
      })
    } : null,

    var.include_default_policies.route53 ? {
      name : "Route53AndACM"
      policy : jsonencode({
        Version : "2012-10-17",
        Statement : local.route53_statements,
      })
    } : null,

    var.include_default_policies.ecr ? {
      name : "ECR"
      policy : jsonencode({
        "Version" : "2012-10-17",
        "Statement" : local.ecr_statements,
      }),
    } : null,

    var.include_default_policies.dynamodb ? {
      name : "DynamoDB"
      policy : jsonencode({
        "Version" : "2012-10-17",
        "Statement" : local.dynamodb_statements,
      }),
    } : null,
  ] : policy if policy != null]
}
