locals {
  app_name = "albumapi"
}

resource "azurecaf_name" "app_name" {
  name          = local.app_name
  resource_type = "azurerm_container_app"
  clean_input   = true
}

resource "azurerm_user_assigned_identity" "albumapi" {
  location            = data.azurerm_resource_group.applications.location
  name                = "id-${local.app_name}"
  resource_group_name = data.azurerm_resource_group.applications.name
}

resource "azurerm_role_assignment" "container_registry_acrpull_user_assigned" {
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.acr.id
  principal_id         = azurerm_user_assigned_identity.albumapi.principal_id

  depends_on = [
    azurerm_user_assigned_identity.albumapi
  ]
}

resource "azurerm_container_app" "application" {
  name                         = azurecaf_name.app_name.result
  container_app_environment_id = data.azurerm_container_app_environment.applications.id
  resource_group_name          = data.azurerm_resource_group.applications.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    container {
      name   = local.app_name
      image  = "crthunebyinfrastructure.azurecr.io/albumapi:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      liveness_probe {
        port      = 8080
        transport = "HTTP"
      }
    }

    http_scale_rule {
      name                = "http"
      concurrent_requests = 10
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.albumapi.id]
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.albumapi.id
  }

  secret {
    name  = "acr-master-key"
    value = data.azurerm_container_registry.acr.admin_password
  }

  dapr {
    app_id       = local.app_name
    app_port     = 8080
    app_protocol = "http"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  depends_on = [
    azurecaf_name.app_name,
    azurerm_user_assigned_identity.albumapi,
    azurerm_role_assignment.container_registry_acrpull_user_assigned
  ]

}


