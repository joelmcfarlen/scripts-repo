resource "aws_secretsmanager_secret" "JenkinsAdminSecret" {
  name        = "momd-jenkins-credentials"
  description = "This is the credentials for the ECS Jenkins deployment"
}

resource "random_integer" "credentials" {
  min = 16
  max = 16
}

resource "random_string" "JenkinsAdminSecretPassword" {
  length = random_integer.credentials.result
  special = true
}

resource "aws_secretsmanager_secret_version" "JenkinsAdminSecretVersion" {
  secret_id           = aws_secretsmanager_secret.JenkinsAdminSecret.id
  secret_string       = random_string.JenkinsAdminSecretPassword.result
  version_stages      = ["AWSCURRENT"]
  depends_on          = [random_string.JenkinsAdminSecretPassword]

  lifecycle {
    ignore_changes = [secret_string]
  }
}
