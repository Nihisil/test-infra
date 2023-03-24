terraform {
  cloud {
    organization = "organization"

    workspaces {
      name = "terraform_workspace"
    }
  }

  # Terraform version
  required_version = "~> 1.3.9"
}

module "ecr" {
  source = "./modules/ecr"

  namespace   = var.namespace
  image_limit = var.image_limit
}
