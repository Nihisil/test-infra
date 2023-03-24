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

module "vpc" {
  source    = "./modules/vpc"

  namespace = var.namespace
}

module "security_group" {
  source = "./modules/security_group"

  namespace                   = var.namespace
  vpc_id                      = module.vpc.vpc_id
  app_port                    = var.app_port
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  nimble_office_ip = var.nimble_office_ip
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  namespace = var.namespace
}

module "s3" {
  source = "./modules/s3"

  namespace   = var.namespace
}

module "alb" {
    source = "./modules/alb"

    vpc_id             = module.vpc.vpc_id
    namespace          = var.namespace
    app_port           = var.app_port
    subnet_ids         = module.vpc.public_subnet_ids
    security_group_ids = module.security_group.alb_security_group_ids
    health_check_path  = var.health_check_path
    enable_stickiness  = var.enable_alb_stickiness
    stickiness_type    = var.alb_stickiness_type
  }



module "rds" {
  source = "./modules/rds"

  namespace = var.namespace

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

module "bastion" {
  source = "./modules/bastion"

  subnet_ids                  = module.vpc.public_subnet_ids
  instance_security_group_ids = module.security_group.bastion_security_group_ids

  namespace     = var.namespace
  image_id      = var.bastion_image_id
  instance_type = var.bastion_instance_type

  min_instance_count     = var.bastion_min_instance_count
  max_instance_count     = var.bastion_max_instance_count
  instance_desired_count = var.bastion_instance_desired_count
}

module "ssm" {
  source = "./modules/ssm"

  namespace = var.namespace

  secrets = {
    database_url = "postgres://${var.rds_username}:${var.rds_password}@${module.rds.db_endpoint}/${var.rds_database_name}"
    secret_key_base = var.secret_key_base
  }
}

module "ecs" {
  source = "./modules/ecs"

  subnets                            = module.vpc.private_subnet_ids
  namespace                          = var.namespace
  region                             = var.region
  app_host                           = module.alb.alb_dns_name
  app_port                           = var.app_port
  ecr_repo_name                      = var.ecr_repo_name
  ecr_tag                            = var.ecr_tag
  security_groups                    = module.security_group.ecs_security_group_ids
  alb_target_group_arn               = module.alb.alb_target_group_arn
  aws_cloudwatch_log_group_name      = module.log.aws_cloudwatch_log_group_name
  desired_count                      = var.ecs.task_desired_count
  cpu                                = var.ecs.task_cpu
  memory                             = var.ecs.task_memory
  deployment_maximum_percent         = var.ecs.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.ecs.deployment_minimum_healthy_percent
  container_memory                   = var.ecs.task_container_memory

  environment_variables = var.environment_variables
  secrets_variables     = module.ssm.secrets_variables
  secrets_arns          = module.ssm.parameter_store_arns
}
