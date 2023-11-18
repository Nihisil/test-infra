variable "environment" {
  description = "The application environment, used to tag the resources, e.g. `staging`, `prod`, ..."
  type        = string
}

variable "owner" {
  description = "The owner of the infrastructure, used to tag the resources, e.g. `acme-web`"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "iam_admin_emails" {
  description = "List of admin emails to provision IAM user account"
  type        = list(string)
}

variable "iam_bot_emails" {
  description = "List of bot emails to provision IAM user account"
  type        = list(string)
}

variable "iam_developer_emails" {
  description = "List of developer emails to provision IAM user account"
  type        = list(string)
}

variable "image_limit" {
  description = "Sets max amount of the latest develop images to be kept"
  type        = number
}
