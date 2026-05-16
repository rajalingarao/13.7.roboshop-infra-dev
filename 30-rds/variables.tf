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

variable "rds_tags" {
    default = {
        Component = "db"
    }
}

variable "zone_name" {
    default = "lithesh.shop"
}
