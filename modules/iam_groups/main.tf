#tfsec:ignore:aws-iam-enforce-group-mfa
resource "aws_iam_group" "admin" {
  name = "Admin-group-alex"
}

#tfsec:ignore:aws-iam-enforce-group-mfa
resource "aws_iam_group" "bot" {
  name = "Bot-group-alex"
}

#tfsec:ignore:aws-iam-enforce-group-mfa
resource "aws_iam_group" "developer" {
  name = "Developer-group-alex"
}

resource "aws_iam_group_policy_attachment" "admin_access" {
  group      = aws_iam_group.admin.name
  policy_arn = data.aws_iam_policy.admin_access.arn
}

# Policy from https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html
# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_group_policy" "developer_allow_manage_own_credentials" {
  group  = aws_iam_group.developer.name
  policy = local.allow_manage_own_credentials
}

resource "aws_iam_group_policy_attachment" "developer_power_user_access" {
  group      = aws_iam_group.developer.name
  policy_arn = data.aws_iam_policy.power_user_access.arn
}

resource "aws_iam_group_policy_attachment" "bot_power_user_access" {
  group      = aws_iam_group.bot.name
  policy_arn = data.aws_iam_policy.power_user_access.arn
}

# This IAM policy is needed for the bot account to manage IAM users & groups
# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_group_policy" "bot_full_iam_access" {
  name   = "AllowFullIamAccess"
  group  = aws_iam_group.bot.name
  policy = local.full_iam_access_policy
}
