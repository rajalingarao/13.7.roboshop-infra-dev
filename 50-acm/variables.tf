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

variable "zone_name" {
    default = "lithesh.shop"
}

variable "zone_id" {
     default = "Z012785114HGZTDQ8KSQH"
}
