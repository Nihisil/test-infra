variable "env_namespace" {
  description = "The namespace with environment for the SSM Parameters, e.g. acme-web-staging"
  type        = string
}

variable "app_name" {
  description = "The application name"
  type        = string
}

variable "secrets" {
  description = "Map of secrets to keep in AWS SSM Parameter Store"
  type        = map(string)
  default     = {}
}
