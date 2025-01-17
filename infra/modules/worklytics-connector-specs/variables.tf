variable "enabled_connectors" {
  type        = list(string)
  description = "ids of connectors to enable"
}

variable "google_workspace_example_user" {
  type        = string
  description = "user to impersonate for Google Workspace API calls (null for none)"
  default     = null
}

variable "msft_tenant_id" {
  type        = string
  default     = ""
  description = "ID of Microsoft tenant to connect to (req'd only if config includes MSFT connectors)"
}

variable "example_msft_user_guid" {
  type        = string
  description = "example MSFT user guid (uuid) for test API calls (OPTIONAL)"
  default     = "{EXAMPLE_MSFT_USER_GUID}"
}
