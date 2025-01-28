variable "resource_group_location" {
  type = string
  default = "westeurope"
}

variable "resource_group_name" {
  type = string
  default = "LynxMedia"
}

variable "azure_subscription" {
  type = string
  sensitive = true
  nullable = false
}

variable "docker_registry_server" {
  type = string
  default = "index.docker.io"
}

variable "docker_registry_username" {
  type = string
  sensitive = true
}

variable "docker_registry_password" {
  type = string
  sensitive = true
}

variable "nginx_tag" {
  type = string
  nullable = false
}