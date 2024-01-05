data "aws_ecr_repository" "repo" {
  name = var.ecr_repo_name
}

# Current task definition on AWS including deployments outside terraform (e.g. CI deployments)
data "aws_ecs_task_definition" "task" {
  task_definition = aws_ecs_task_definition.main.family
}
