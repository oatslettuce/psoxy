
# module to give users instructions on how to create a API token/key externally, and fill it in the
# proper place
#
# use case: sources which don't support connections provisioned via API (or Terraform)

resource "local_file" "source_connection_instructions" {
  filename = "TODO ${var.todo_step} - setup ${var.source_id}.md"
  content  = <<EOT
# TODO - Create User-Managed Token for ${var.source_id}

Follow the following steps:

${var.connector_specific_external_steps}

${join("\n", var.additional_steps)}
EOT
}

output "next_todo_step" {
  value = var.todo_step + 1
}
