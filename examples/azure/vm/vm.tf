# --- RESOURCES / MODULES ---

module "vm" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/vm"
  source = "../../../azure/vm"

  name                = "they-test-vm"
  resource_group_name = "they-dev"
  custom_data = base64encode(templatefile("setup_instance.yml", {
    hello = "world"
  }))
  vm_password       = "P@ssw0rd123!"
  vm_public_ssh_key = file("insecure-key.pub") # never use this key anywhere
  public_ip         = true
  allow_ssh         = true
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

# --- OUTPUT ---

output "vm_id" {
  value = module.vm.vm_id
}

output "nsg_name" {
  value = module.vm.nsg_name
}

output "connect_instructions" {
  value = "Connect to your VM with: ssh -i ${path.cwd}/insecure-key ${module.vm.vm_username}@${module.vm.public_ip}"
}

output "mock_server_url" {
  value = "http://${module.vm.public_ip}/"
}
