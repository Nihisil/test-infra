terraform {
  cloud {
    organization = "nimble"
    workspaces {
      name = "test-infra"
    }
  }
  # Terraform version
  required_version = "1.5.5"
}

locals {
  env_namespace = "test-infra-${var.environment}"
}

module "vpc" {
  source = "../modules/vpc"

  env_namespace = local.env_namespace
}

module "security_group" {
  source = "../modules/security_group"

  env_namespace               = local.env_namespace
  vpc_id                      = module.vpc.vpc_id
  app_port                    = var.app_port
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  nimble_office_ip = var.nimble_office_ip
}

module "bastion" {
  source = "../modules/bastion"

  subnet_ids                  = module.vpc.public_subnet_ids
  instance_security_group_ids = module.security_group.bastion_security_group_ids

  env_namespace = local.env_namespace
  image_id      = var.bastion_image_id
  instance_type = var.bastion_instance_type

  min_instance_count     = var.bastion_min_instance_count
  max_instance_count     = var.bastion_max_instance_count
  instance_desired_count = var.bastion_instance_desired_count
}

module "rds" {
  source = "../modules/rds"

  env_namespace = local.env_namespace

  vpc_security_group_ids = module.security_group.rds_security_group_ids
  vpc_id                 = module.vpc.vpc_id

  subnet_ids = module.vpc.private_subnet_ids

  instance_type = var.rds_instance_type
  database_name = var.rds_database_name
  username      = var.rds_username
  password      = var.rds_password

  autoscaling_min_capacity = var.rds_autoscaling_min_capacity
  autoscaling_max_capacity = var.rds_autoscaling_max_capacity
}

module "ecs" {
  source = "../modules/ecs"

  subnets                            = module.vpc.private_subnet_ids
  env_namespace                      = local.env_namespace
  region                             = var.region
  app_host                           = module.alb.alb_dns_name
  app_port                           = var.app_port
  ecr_repo_name                      = var.ecr_repo_name
  ecr_tag                            = var.ecr_tag
  security_groups                    = module.security_group.ecs_security_group_ids
  alb_target_group_arn               = module.alb.alb_target_group_arn
  aws_cloudwatch_log_group_name      = module.cloudwatch.aws_cloudwatch_log_group_name
  desired_count                      = var.ecs_config.task_desired_count
  cpu                                = var.ecs_config.task_cpu
  memory                             = var.ecs_config.task_memory
  deployment_maximum_percent         = var.ecs_config.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.ecs_config.deployment_minimum_healthy_percent
  container_memory                   = var.ecs_config.task_container_memory

  # Auto-scaling
  min_instance_count                   = var.ecs_config.min_instance_count
  max_instance_count                   = var.ecs_config.max_instance_count
  autoscaling_target_cpu_percentage    = var.ecs_config.autoscaling_target_cpu_percentage
  autoscaling_target_memory_percentage = var.ecs_config.autoscaling_target_memory_percentage

  environment_variables = var.environment_variables
  secrets_variables     = module.ssm.secrets_variables
  secrets_arns          = module.ssm.parameter_store_arns
}

module "alb" {
  source = "../modules/alb"

  vpc_id             = module.vpc.vpc_id
  env_namespace      = local.env_namespace
  app_port           = var.app_port
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = module.security_group.alb_security_group_ids
  health_check_path  = var.health_check_path
}

module "cloudwatch" {
  source = "../modules/cloudwatch"

  env_namespace = local.env_namespace

  log_retention_in_days = var.cloudwatch_log_retention_in_days
}

module "s3" {
  source = "../modules/s3"

  env_namespace = local.env_namespace
}

module "ssm" {
  source = "../modules/ssm"

  env_namespace = local.env_namespace

  secrets = {
    database_url    = "postgres://${var.rds_username}:${var.rds_password}@${module.rds.db_endpoint}/${var.rds_database_name}"
    secret_key_base = var.secret_key_base
  }
}
