# Outbound proxy VPC

Whenever you need to talk to APIs which use IP based whitelisting, this is
the module to create the required setup with. It requires an eip/elastic ip
and it spits out a vpc\_config which can be attached to a lambda function. The
lambda function will then execute requests via the ip of the given eip.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eip_allocation_id"></a> [eip\_allocation\_id](#input\_eip\_allocation\_id) | The allocation id of the elastic ip address. The public ip of this eip will be used as the outbound ip of the proxy. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name/Prefix of resources created by this module. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to the created resources of this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | Arn of the created vpc. |
| <a name="output_vpc_config"></a> [vpc\_config](#output\_vpc\_config) | By attaching this config to the vpc\_config block of a lambda function it uses the outbound proxy. |
