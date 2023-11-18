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

module "iam_bot_users" {
  source = "../modules/iam_users"

  usernames = var.iam_bot_emails
}

module "iam_admin_group_membership" {
  source = "../modules/iam_group_membership"

  name  = "admin-group-membership"
  group = module.iam_groups.admin_group
  users = var.iam_admin_emails
}

module "iam_bot_group_membership" {
  source = "../modules/iam_group_membership"

  name  = "bot-group-membership"
  group = module.iam_groups.bot_group
  users = var.iam_bot_emails
}

module "iam_developer_group_membership" {
  source = "../modules/iam_group_membership"

  name  = "developer-group-membership"
  group = module.iam_groups.developer_group
  users = var.iam_developer_emails
}
#
#module "ecr" {
#  source = "../modules/ecr"
#
#  env_namespace = local.env_namespace
#  image_limit   = var.image_limit
#}
