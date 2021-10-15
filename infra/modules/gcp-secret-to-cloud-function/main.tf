# expose a Secret Manager secret to a Cloud function

locals {
  secret_version_number = trimprefix(var.secret_version_name, "${var.secret_name}/versions/")
  slugified_secret_name = replace(var.secret_name, "/", "-")
}

resource "google_secret_manager_secret_iam_member" "grant_sa_accessor_on_secret" {
  member    = "serviceAccount:${var.service_account_email}"
  role      = "roles/secretmanager.secretAccessor"
  secret_id = var.secret_name
}

# terraform
resource "local_file" "todo" {
  filename = "TODO ${var.function_name} - link ${local.slugified_secret_name}.md"
  content  = <<EOT
Run the following command to finish exposing  `${local.slugified_secret_name}` to `${var.function_name}`:

```shell
gcloud functions deploy ${var.function_name} \
    --runtime=${var.runtime} \
    --update-secrets 'SERVICE_ACCOUNT_KEY=${var.secret_name}:${local.secret_version_number}'
```
EOT
}
