terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

variable "email" {
    description = "email address to send notifications"
}

variable "port" {
    description = "http port to expose"
    default = 8000
}

variable "title" {
    description = "title of the app"
    default = "Welocome Terraform"
}
variable "color" {
    description = "color of the app"
    default = "gray"
}

variable "body" {
  description = "body of the web page"
  default = "Please use title/color/body tf vars"
}
provider "docker" {
  # Configuration options
}

resource "docker_container" "web" {
  name  = "web"
  image = docker_image.coffee.image_id
  ports{
    internal = 80
    external = var.port
  }
  env = [
    "TITLE=${upper(var.title)} email:${var.email}",
    "COLOR=${var.color}",
    "BODY=${var.body}"
  ]
}

resource "docker_image" "coffee" {
  name = "lalyos/12factor"
}

output "port" {
    value = docker_container.web.ports[0].external
    sensitive = true
}
output "url" {
  value = "http://localhost:${var.port}"
}