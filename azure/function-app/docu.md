## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_archive"></a> [archive](#input\_archive) | Archive configuration. | <pre>object({<br>    output_path = optional(string, null)<br>    excludes    = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_build"></a> [build](#input\_build) | Build configuration. | <pre>object({<br>    enabled   = optional(bool, true)<br>    command   = optional(string, "yarn run build")<br>    build_dir = optional(string, "dist")<br>  })</pre> | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Map of environment variables that are accessible from the function code during execution. | `map(string)` | `{}` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | The identity. | <pre>object({<br>    name = string<br>  })</pre> | `null` | no |
| <a name="input_insights"></a> [insights](#input\_insights) | Application insights. | <pre>object({<br>    enabled           = optional(bool, true)<br>    sku               = optional(string, "PerGB2018")<br>    retention_in_days = optional(number, 30)<br>  })</pre> | `{}` | no |
| <a name="input_is_bundle"></a> [is\_bundle](#input\_is\_bundle) | If true, node\_modules and .yarn directories will be excluded from the archive. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure region where the resources should be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the function app. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the function app. | `string` | n/a | yes |
| <a name="input_service_plan"></a> [service\_plan](#input\_service\_plan) | The service plan. | <pre>object({<br>    name     = optional(string, null)<br>    os_type  = optional(string, "Windows")<br>    sku_name = optional(string, "Y1")<br>  })</pre> | `{}` | no |
| <a name="input_source_dir"></a> [source\_dir](#input\_source\_dir) | Directory containing the function code. | `string` | n/a | yes |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | The storage account. | <pre>object({<br>    preexisting_name = optional(string, null)<br>    is_hns_enabled   = optional(bool, false)<br>    tier             = optional(string, "Standard")<br>    replication_type = optional(string, "RAGRS") # Read-access geo-redundant storage (RA-GRS)<br>    min_tls_version  = optional(string, "TLS1_2")<br>  })</pre> | `{}` | no |
| <a name="input_storage_trigger"></a> [storage\_trigger](#input\_storage\_trigger) | Storage trigger configuration. | <pre>object({<br>    function_name                = string<br>    events                       = list(string)<br>    trigger_storage_account_name = optional(string) # defaults to the storage account of the function app<br>    trigger_resource_group_name  = optional(string) # defaults to the resource group of the function app<br>    subject_filter = optional(object({<br>      subject_begins_with = optional(string)<br>      subject_ends_with   = optional(string)<br>    }))<br>    retry_policy = optional(object({<br>      event_time_to_live    = optional(number, 360)<br>      max_delivery_attempts = optional(number, 1)<br>    }), { event_time_to_live = 360, max_delivery_attempts = 1 })<br>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_archive_file_path"></a> [archive\_file\_path](#output\_archive\_file\_path) | n/a |
| <a name="output_build"></a> [build](#output\_build) | n/a |
| <a name="output_endpoint_url"></a> [endpoint\_url](#output\_endpoint\_url) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
