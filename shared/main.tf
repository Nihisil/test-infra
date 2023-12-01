terraform {
  cloud {
    organization = "alex-personal-terraform"
    workspaces {
      name = "test-infra-shared"
    }
  }
  # Terraform version
  required_version = "1.5.5"
}

locals {
  env_namespace = "test-infra-${var.environment}"
}

module "iam_groups" {
  source = "../modules/iam_groups"
}

module "iam_admin_users" {
  source = "../modules/iam_users"

  usernames = var.iam_admin_emails
}

module "iam_developer_users" {
  source = "../modules/iam_users"

  usernames = var.iam_developer_emails
}

module "iam_infra_service_account_users" {
  source = "../modules/iam_users"

  usernames = var.iam_infra_service_account_emails
  has_login = false
}

module "iam_group_membership" {
  source = "../modules/iam_group_membership"

  for_each = {
    admin                 = { group = module.iam_groups.admin_group, users = var.iam_admin_emails },
    infra_service_account = { group = module.iam_groups.infra_service_account_group, users = var.iam_infra_service_account_emails },
    developer             = { group = module.iam_groups.developer_group, users = var.iam_developer_emails }
  }

  name  = "${each.key}-group-membership"
  group = each.value.group
  users = each.value.users

  depends_on = [
    module.iam_groups,
    module.iam_admin_users,
    module.iam_developer_users,
    module.iam_infra_service_account_users,
  ]
}
#
#module "ecr" {
#  source = "../modules/ecr"
#
#  env_namespace = local.env_namespace
#  image_limit   = var.image_limit
#}
