// All security groups

resource "aws_security_group" "bastion" {
  name        = "${var.env_namespace}-bastion"
  description = "Bastion Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_namespace}-bastion-sg"
  }
}

resource "aws_security_group_rule" "bastion_ingress_ssh_nimble" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.nimble_office_ip}/32"]
  description       = "Nimble office"
}

resource "aws_security_group_rule" "bastion_egress_rds" {
  type                     = "egress"
  security_group_id        = aws_security_group.bastion.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "From RDS to bastion"
}

resource "aws_security_group" "rds" {
  name        = "${var.env_namespace}-rds"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_namespace}-rds-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress_app_fargate" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_fargate.id
  description              = "From app to DB"
}

resource "aws_security_group_rule" "rds_ingress_bastion" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  description              = "From bastion to RDS"
}

resource "aws_security_group" "ecs_fargate" {
  name        = "${var.env_namespace}-ecs-fargate-sg"
  description = "ECS Fargate Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_namespace}-ecs-fargate-sg"
  }
}

resource "aws_security_group_rule" "ecs_fargate_ingress_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs_fargate.id
  protocol                 = "tcp"
  from_port                = var.app_port
  to_port                  = var.app_port
  source_security_group_id = aws_security_group.alb.id
  description              = "From internal VPC to app"
}

resource "aws_security_group_rule" "ecs_fargate_ingress_private" {
  type              = "ingress"
  security_group_id = aws_security_group.ecs_fargate.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = var.private_subnets_cidr_blocks
  description       = "From internal VPC to app"
}

# trivy:ignore:AVD-AWS-0104
resource "aws_security_group_rule" "ecs_fargate_egress_anywhere" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_fargate.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "From app to everywhere"
}

resource "aws_security_group" "alb" {
  name        = "${var.env_namespace}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_namespace}-alb-sg"
  }
}

# trivy:ignore:AVD-AWS-0107
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "From HTTPS to ALB"
}

# trivy:ignore:AVD-AWS-0107
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "From HTTP to ALB"
}

# trivy:ignore:AVD-AWS-0104
resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  protocol          = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "From ALB to app"
}
