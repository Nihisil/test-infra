resource "aws_iam_policy" "ecs_task_execution_ssm" {
  name   = "${local.env_app_name}-ECSTaskExecutionAccessSSMPolicy"
  policy = local.ecs_task_execution_ssm_policy
}

# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "ecs_task_execution_service_scaling" {
  name   = "${local.env_app_name}-ECSAutoScalingPolicy"
  policy = local.ecs_service_scaling_policy
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.env_app_name}-ecs-execution-role"
  assume_role_policy = local.ecs_task_execution_assume_role_policy
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_service_scaling_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_service_scaling.arn
}

resource "aws_ecs_task_definition" "main" {
  family                   = local.service_name
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = local.container_definitions
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "main" {
  name                               = "${local.env_app_name}-ecs-service"
  cluster                            = var.ecs_cluster_id
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  desired_count                      = var.desired_count
  task_definition                    = "${aws_ecs_task_definition.main.family}:${max("${aws_ecs_task_definition.main.revision}", "${data.aws_ecs_task_definition.task.revision}")}"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets         = var.subnets
    security_groups = var.security_groups
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = local.env_app_name
    container_port   = var.app_port
  }

  # Allow external changes without Terraform plan to the desired_count as it can be changed by Autoscaling
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "main" {
  max_capacity       = var.max_instance_count
  min_capacity       = var.min_instance_count
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "memory_policy" {
  name               = "${local.env_app_name}-appautoscaling-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = local.scale_in_cooldown_period
    scale_out_cooldown = local.scale_out_cooldown_period

    target_value = var.autoscaling_target_memory_percentage
  }
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "${local.env_app_name}-appautoscaling-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = local.scale_in_cooldown_period
    scale_out_cooldown = local.scale_out_cooldown_period

    target_value = var.autoscaling_target_cpu_percentage
  }
}
