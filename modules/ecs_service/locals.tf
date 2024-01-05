locals {
  env_app_name = "${var.env_namespace}-${var.app_name}"
  service_name = "${local.env_app_name}-service"
  # The minimum time (in seconds) between two scaling-in/out activities
  scale_in_cooldown_period  = 300
  scale_out_cooldown_period = 300

  # Environment variables from other variables
  environment_variables = toset([
    {
      name  = "AWS_REGION"
      value = var.region
    }
  ])

  container_vars = {
    container_name                     = local.env_app_name
    region                             = var.region
    app_port                           = var.app_port
    deployment_maximum_percent         = var.deployment_maximum_percent
    deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
    aws_ecr_repository                 = data.aws_ecr_repository.repo.repository_url
    aws_ecr_tag                        = var.ecr_tag
    aws_cloudwatch_log_group_name      = var.aws_cloudwatch_log_group_name

    environment_variables = setunion(local.environment_variables, var.environment_variables)
    secrets_variables     = var.secrets_variables
  }

  container_definitions = templatefile("${path.module}/service.json.tftpl", local.container_vars)

  ecs_task_execution_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  ecs_task_execution_ssm_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters"
        ],
        Resource = var.secrets_arns
      }
    ]
  })

  # Required IAM permissions from
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html#auto-scaling-IAM
  ecs_service_scaling_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "application-autoscaling:*",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:EnableAlarmActions",
          "iam:CreateServiceLinkedRole",
          "sns:CreateTopic",
          "sns:Subscribe",
          "sns:Get*",
          "sns:List*"
        ],
        Resource = "*"
      }
    ]
  })
}
