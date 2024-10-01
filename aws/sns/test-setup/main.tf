# locals {
#   topic_name = "test-topic"
# }
#
# data "aws_region" "current" {}
# data "aws_caller_identity" "current" {}
#
# output "region" {
#   value = data.aws_region.current
# }
#
# output "aws_caller_identity" {
#   value = data.aws_caller_identity.current
# }
#
# output "topic_name_fifo" {
#   value = local.topic_name
# }
#
# output "topic_name_fifo" {
#   value = local.topic_name
# }

output "access_policy" {
  value = "{}" # no access to anyone
}
