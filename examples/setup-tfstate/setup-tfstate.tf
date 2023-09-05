# --- RESOURCES / MODULES ---

module "setup_tfstate" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/setup-tfstate"
  source = "../../aws/setup-tfstate"

  name = "they-example"
}
