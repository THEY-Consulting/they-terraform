variable "name" {
  description = "Name of the vm."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
}

variable "vm_hostname" {
  description = "The host name of the VM."
  type        = string
  default     = null
}

variable "vm_os" {
  description = "The OS to use for the VM. Valid values are 'linux' or 'windows'."
  type        = string
  default     = "linux"
}

variable "vm_size" {
  description = "The size of the VM to create."
  type        = string
  default     = "Standard_B2s"
}

variable "vm_username" {
  description = "The username for the VM admin user."
  type        = string
  default     = "they"
}

variable "vm_password" {
  description = "The password of the VM admin user."
  type        = string
  sensitive   = true
}

variable "vm_public_ssh_key" {
  description = "Public SSH key to use for the VM."
  type        = string
  default     = null
}

variable "custom_data" {
  description = "The custom data to setup the VM."
  type        = string
  default     = null
}

variable "vm_image" {
  description = "The image to use for the VM."
  type = object({
    publisher = optional(string, "Canonical")
    offer     = optional(string, "0001-com-ubuntu-server-jammy")
    sku       = optional(string, "22_04-lts-gen2")
    version   = optional(string, "latest")
  })
  default = {}
}

variable "network" {
  description = "The network config to use for the VM."
  type = object({
    preexisting_name = optional(string, null)
    address_space    = optional(list(string), ["10.0.0.0/16"])
  })
  default = {}
}

variable "subnet_address_prefix" {
  description = "The address prefix to use for the subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "routes" {
  description = "The routes to use for the VM."
  type = list(object({
    name           = string
    address_prefix = string
    next_hop_type  = string
  }))
  default = [{
    name           = "all_traffic"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }]
}

variable "public_ip" {
  description = "Enable a static public IP for the VM."
  type        = bool
  default     = false
}

variable "allow_ssh" {
  description = "Allow SSH access to the VM."
  type        = bool
  default     = false
}

variable "allow_rdp" {
  description = "Allow RDP access to the VM."
  type        = bool
  default     = false
}

variable "security_rules" {
  description = "The security rules to use for the VM."
  type = list(object({
    name                   = string
    description            = optional(string, "")
    direction              = optional(string, "Inbound")
    access                 = optional(string, "Allow")
    priority               = number
    protocol               = optional(string, "Tcp")
    source_port_range      = optional(string, "*")
    source_address_prefix  = optional(string, "*")
    destination_port_range = string
  }))
  default = []
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
