# makes grant on behalf of ALL users in your Azure AD directory
#  - there is no way to do another org unit / group via Terraform; if that's the configure you
#   desire, you'll have to do that via Azure AD console OR cli

terraform {
  required_providers {
    azuread = {
      version = "~> 2.15.0"
    }
  }
}

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_service_principal" "connector" {
  application_id = var.application_id
  use_existing   = true
}

locals {
  oauth2_permission_scope_ids = [for name in var.oauth2_permission_scopes : azuread_service_principal.msgraph.oauth2_permission_scope_ids[name]]
  app_role_ids                = [for name in var.app_roles : azuread_service_principal.msgraph.app_role_ids[name]]
}

resource "azuread_service_principal_delegated_permission_grant" "grant" {
  service_principal_object_id          = azuread_service_principal.connector.object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values                         = concat(local.app_role_ids, local.oauth2_permission_scope_ids)
}