
output "iam_admin_temporary_passwords" {
  description = "List of first time passwords for admin accounts. Must be changed at first time login and will no longer be valid."
  value       = module.iam_admin_users.temporary_passwords
}

output "iam_developer_temporary_passwords" {
  description = "List of first time passwords for developer accounts. Must be changed at first time login and will no longer be valid."
  value       = module.iam_developer_users.temporary_passwords
}
