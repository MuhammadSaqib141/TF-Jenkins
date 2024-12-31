provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "saqibrg-secret-rotation"
  location = "East US"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "saqib-kv-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id

}

resource "azurerm_eventhub_namespace" "eventhub" {
  name                = "saqib-eventhub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "eventhub" {
  name                    = "secret-rotation-eventhub"
  namespace_id      = azurerm_eventhub_namespace.eventhub.id
  partition_count         = 2
  message_retention       = 1
}

resource "azurerm_eventgrid_system_topic" "kv_system_topic" {
  name                = "keyvault-system-topic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  source_arm_resource_id   = azurerm_key_vault.kv.id
  topic_type          = "Microsoft.KeyVault.vaults"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "kv_expiry_event_subscription" {
  name                             = "kv-expiry-subscription"
  eventhub_endpoint_id              = azurerm_eventhub.eventhub.id
  resource_group_name = azurerm_resource_group.rg.name
  system_topic = azurerm_eventgrid_system_topic.kv_system_topic.name

  included_event_types = [
    "Microsoft.KeyVault.SecretNearExpiry"
  ]
}




resource "azurerm_key_vault" "kv" {
  name                = "saqib-kv-tf-testt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id

}


resource "azurerm_eventgrid_system_topic_event_subscription" "kv_expiry_event_subscription" {
  name                             = "kv-expiry-subscription"
  eventhub_endpoint_id              = azurerm_eventhub.eventhub.id
  resource_group_name = azurerm_resource_group.rg.name
  system_topic = azurerm_eventgrid_system_topic.kv_system_topic.name

  included_event_types = [
    "Microsoft.KeyVault.SecretNearExpiry"
  ]
}