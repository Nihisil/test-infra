# Append a random string to the secret names because once we tear down the infra, the secret does not actually
# get deleted right away, which means that if we try to recreate the infra, it'll fail as the
# secret name already exists.
resource "random_string" "service_secret_random_suffix" {
  length  = 6
  special = false
}

resource "aws_ssm_parameter" "secret_parameters" {
  for_each = var.secrets

  name        = "/${var.env_namespace}/${var.app_name}/${each.key}-${random_string.service_secret_random_suffix.result}"
  description = "Secret '${lower(each.key)}' for ${var.env_namespace}"
  type        = "String"
  value       = each.value
}

locals {
  # Create a list of parameter store ARNs for granting access to ECS task execution role
  parameter_store_arns = [for parameter in aws_ssm_parameter.secret_parameters : parameter.arn]

  # Get secret names array
  secret_names = keys(var.secrets)

  # Create a map {secret_name: secret_arn} using zipmap function for iteration
  secret_arns = zipmap(local.secret_names, local.parameter_store_arns)

  # Create the formatted secrets for ECS task definition
  secrets_variables = [for secret_key, secret_arn in local.secret_arns :
    tomap({ "name" = upper(secret_key), "valueFrom" = secret_arn })
  ]
}
