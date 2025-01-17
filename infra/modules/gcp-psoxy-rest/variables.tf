variable "project_id" {
  type        = string
  description = "name of the gcp project"
}

variable "region" {
  type        = string
  description = "region into which to deploy function"
  default     = "us-central1"
}

variable "instance_id" {
  type        = string
  description = "kind of source (eg, 'gmail', 'google-chat', etc)"
}

variable "service_account_email" {
  type        = string
  description = "email of the service account that the cloud function will run as"
}

variable "secret_bindings" {
  type = map(object({
    secret_id      = string # NOT the full resource ID; just the secret_id within GCP project
    version_number = string # could be 'latest'
  }))
  description = "map of Secret Manager Secrets to expose to cloud function by ENV_VAR_NAME"
  default     = {}
}

variable "artifacts_bucket_name" {
  type        = string
  description = "Name of the bucket where artifacts are stored"
}

variable "deployment_bundle_object_name" {
  type        = string
  description = "Name of the object containing the deployment bundle"
}

variable "path_to_repo_root" {
  type        = string
  description = "the path where your psoxy repo resides"
  default     = "../../.."
}

variable "path_to_config" {
  type        = string
  description = "path to config file (usually something in ../../configs/, eg configs/gdirectory.yaml"
  default     = null
}

variable "salt_secret_id" {
  type        = string
  description = "Id of the secret used to salt pseudonyms"
}

variable "salt_secret_version_number" {
  type        = string
  description = "Version number of the secret used to salt pseudonyms"
  validation {
    condition     = can(regex("^([0-9]+)|latest$", var.salt_secret_version_number))
    error_message = "Version number must be a number or 'latest'."
  }
}

variable "example_api_calls" {
  type        = list(string)
  description = "example endpoints that can be called via proxy"
  default     = []
}

variable "example_api_calls_user_to_impersonate" {
  type        = string
  description = "if example endpoints require impersonation of a specific user, use this id"
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "Non-sensitive values to add to functions environment variables; NOTE: will override anything in `path_to_config`"
  default     = {}
}

variable "source_kind" {
  type        = string
  description = "kind of source to which you're connecting"
  default     = "unknown"
}


variable "todo_step" {
  type        = number
  description = "of all todos, where does this one logically fall in sequence"
  default     = 1
}
