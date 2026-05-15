resource "aws_ssm_parameter" "db_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project_name}/${var.environment}/db_sg_id"
  type  = "String"
  value = module.db_sg.id
}

resource "aws_ssm_parameter" "eks_control_plane_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project_name}/${var.environment}/eks_control_plane_sg_id"
  type  = "String"
  value = module.eks_control_plane_sg.id
}

resource "aws_ssm_parameter" "node_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project_name}/${var.environment}/node_sg_id"
  type  = "String"
  value = module.node_sg.id
}

resource "aws_ssm_parameter" "ingress_alb_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project_name}/${var.environment}/ingress_alb_sg_id"
  type  = "String"
  value = module.ingress_alb_sg.id
}

resource "aws_ssm_parameter" "bastion_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project_name}/${var.environment}/bastion_sg_id"
  type  = "String"
  value = module.bastion_sg.id
}

