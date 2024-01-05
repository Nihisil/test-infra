resource "aws_ecs_cluster" "main" {
  name = "${var.env_namespace}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
