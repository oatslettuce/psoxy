variable "project_id" {
  type        = string
  description = "id of GCP project that will host psoxy instance"
}

variable "worklytics_sa_emails" {
  type        = list(string)
  description = "service accounts for your organization's Worklytics instances (list supported for test/dev scenarios)"
}

variable "region" {
  type        = string
  description = "region into which to deploy function / its buckets"
  default     = "us-central1"
}

variable "source_kind" {
  type        = string
  description = "Kind of the content to process"
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

variable "path_to_config" {
  type        = string
  description = "path to config file (usually something in ../../configs/, eg configs/gdirectory.yaml"
  default     = null
}

variable "psoxy_base_dir" {
  type        = string
  description = "the path where your psoxy repo resides. Preferably a full path, /home/user/repos/, avoid tilde (~) shortcut to $HOME"
  default     = "../../.."
}

variable "environment_variables" {
  type        = map(string)
  description = "Non-sensitive values to add to functions environment variables; NOTE: will override anything in `path_to_config`"
  default     = {}
}

variable "bucket_write_role_id" {
  type        = string
  description = "The id of role to grant on bucket to enable writes"
}
