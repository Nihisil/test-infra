variable "environment" {
  description = "The application environment, used to tag the resources, e.g. `staging`, `prod`, ..."
  type        = string
}

variable "owner" {
  description = "The owner of the infrastructure, used to tag the resources, e.g. `acme-web`"
  type        = string
}

variable "app_port" {
  description = "Application running port"
  type        = number
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "nimble_office_ip" {
  description = "Nimble Office IP"
}

variable "bastion_image_id" {
  description = "The AMI image ID for the bastion instance"
  default     = "ami-0801a1e12f4a9ccc0"
}

variable "bastion_instance_type" {
  description = "The bastion instance type"
  default     = "t3.nano"
}

variable "bastion_instance_desired_count" {
  description = "The desired number of the bastion instance"
  default     = 1
}

variable "bastion_max_instance_count" {
  description = "The maximum number of the instance"
  default     = 1
}

variable "bastion_min_instance_count" {
  description = "The minimum number of the instance"
  default     = 1
}

#variable "rds_instance_type" {
#  description = "The RDB instance type"
#  type        = string
#}
#
#variable "rds_database_name" {
#  description = "RDS database name"
#  type        = string
#}
#
#variable "rds_username" {
#  description = "RDS username"
#  type        = string
#}
#
#variable "rds_password" {
#  description = "RDS password"
#  type        = string
#}
#
#variable "rds_autoscaling_min_capacity" {
#  description = "Minimum number of RDS read replicas when autoscaling is enabled"
#  type        = number
#}
#
#variable "rds_autoscaling_max_capacity" {
#  description = "Maximum number of RDS read replicas when autoscaling is enabled"
#  type        = number
#}

variable "ecr_repo_name" {
  description = "ECR repo name"
  type        = string
}

variable "ecr_tag" {
  description = "ECR tag to deploy"
  type        = string
}

variable "ecs_config" {
  description = "ECS input variables"
  type = object({
    task_cpu                           = number
    task_memory                        = number
    task_desired_count                 = number
    task_container_memory              = number
    deployment_maximum_percent         = number
    deployment_minimum_healthy_percent = number

    # Auto-scaling
    min_instance_count                   = number
    max_instance_count                   = number
    autoscaling_target_cpu_percentage    = number
    autoscaling_target_memory_percentage = number
  })
}

variable "environment_variables" {
  description = "List of [{name = \"\", value = \"\"}] pairs of environment variables"
  type = set(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "AVAILABLE_LOCALES"
      value = "en"
    },
    {
      name  = "DEFAULT_LOCALE"
      value = "en"
    },
    {
      name  = "FALLBACK_LOCALES"
      value = "en"
    },
    {
      name  = "MAILER_DEFAULT_HOST"
      value = "localhost"
    },
    {
      name  = "MAILER_DEFAULT_PORT"
      value = "80"
    },
  ]
}

variable "health_check_path" {
  description = "Application health check path"
  type        = string
}

variable "domain" {
  description = "Application domain"
  type        = string
}

variable "cloudwatch_log_retention_in_days" {
  description = "How long (days) to retain the cloudwatch log data"
  default     = 365
}

variable "secret_key_base" {
  description = "The Secret key base for the application"
  type        = string
}
