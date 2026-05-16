variable "project_name" {
    default = "roboshop"
}

variable "environment" {
    default = "dev"
}

variable "common_tags" {
    default = {
        Project = "roboshop"
        Terraform = "true"
        Environment = "dev"
    }
}

variable "db_sg_tags" {
    default = {
        Component = "db"
    }
}

variable "backend_sg_tags" {
    default = {
        Component = "backend"
    }
}

variable "frontend_sg_tags" {
    default = {
        Component = "frontend"
    }
}

variable "bastion_sg_tags" {
    default = {
        Component = "bastion"
    }
}