locals {
  # same port for all apps
  app_port = 80

  environments = ["staging", "production"]

  ###### ECS ######
  current_ecs_config = local.ecs_config[var.environment]
  ecs_config = {
    staging    = jsondecode(file("assets/ecs_configs/staging.json"))
    production = jsondecode(file("assets/ecs_configs/production.json"))
  }

  ###### Container Variables ######
  services = ["website"]

  # public vars that are common to all environments
  common_env_vars = [{ name = "PORT", value = local.app_port }]

  current_container_variables = merge(
    local.container_variables[var.environment],
    { for svc, vars in local.container_variables[var.environment] : svc => concat(vars, local.common_env_vars) }
  )
  # public vars that are specific to each environment
  container_variables = { for env in local.environments : env => {
    for svc in local.services : svc => [for k, v in jsondecode(file(format("assets/container_variables/%s/%s.json", svc, env))) : {
      name  = k
      value = v
    }]
    }
  }

  ###### Apps configs ######

  app_health_path = {
    website = "/"
  }

  apps = {
    website = {
      secrets = {
        secret_key_base = var.secret_key_base
      }
      ecs_config              = local.current_ecs_config.website_ecs_config
      ecs_container_variables = local.current_container_variables.website
    }
  }
}
