resource "aws_efs_file_system" "main" {
  encrypted                       = true
  provisioned_throughput_in_mibps = 0
  throughput_mode                 = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_archive = "AFTER_90_DAYS"
  }

  protection {
    replication_overwrite = "ENABLED"
  }

  tags = {
    Name = "${terraform.workspace}-they-terraform-asg-efs"
  }
}

resource "aws_efs_file_system_policy" "policy" {
  file_system_id = aws_efs_file_system.main.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "FileSystemPolicy",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientMount"
        ],
        "Resource" : aws_efs_file_system.main.arn,
        "Condition" : {
          "Bool" : {
            "elasticfilesystem:AccessedViaMountTarget" : "true"
          }
        }
      }
    ]
  })
}

resource "aws_efs_mount_target" "ec2" {
  count = length(module.auto-scaling-group.private_subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = module.auto-scaling-group.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}
