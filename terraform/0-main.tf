terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.6"
    }
  }
  backend "local" {
    path = "/tmp/runner/work/laravel-vite-docker/laravel-vite-docker/terraform"
    workspace_dir = "/tmp/runner/work/laravel-vite-docker/laravel-vite-docker/terraform"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription
}

resource "random_string" "rand_id" {
  length = 4
  special = false
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${var.resource_group_name}-${random_string.rand_id.id}"
}