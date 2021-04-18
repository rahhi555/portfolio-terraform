// fierbase authのキー
resource "aws_secretsmanager_secret" "firebase_auth_key" {
  name = "firebase-auth-key"
}

variable "firebase_auth_key" {
  default = {
    API_KEY="default"
    AUTH_DOMAIN="default"
    DATABASE_URL="default"
    PROJECT_ID="default"
    STORAGE_BUCKET="default"
    MESSAGE_SENDER_ID="default"
    APP_ID="default"
    MEASUREMENT_ID="default"
    FIREBASE_TOKEN="default"
    ADMIN_KEY_PATH="default"
  }

  type = map(string)
}

resource "aws_secretsmanager_secret_version" "firebase_auth_key" {
  secret_id     = aws_secretsmanager_secret.firebase_auth_key.id
  secret_string = jsonencode(var.firebase_auth_key)

  lifecycle {
    ignore_changes = [secret_string]
  }
}

// firebase admin sdk のキー
resource "aws_secretsmanager_secret" "firebase_admin_key" {
  name = "firebase-admin-key"
}

variable "firebase_admin_key" {
  default = {
    "type"="default"
    "project_id"="default"
    "private_key_id"="default"
    "private_key"="default"
    "client_email"="default"
    "client_id"="default"
    "auth_uri"="default"
    "token_uri"="default"
    "auth_provider_x509_cert_url"="default"
    "client_x509_cert_url"="default"
  }

  type = map(string)
}

resource "aws_secretsmanager_secret_version" "firebase_admin_key" {
  secret_id     = aws_secretsmanager_secret.firebase_admin_key.id
  secret_string = jsonencode(var.firebase_admin_key)

  lifecycle {
    ignore_changes = [secret_string]
  }
}