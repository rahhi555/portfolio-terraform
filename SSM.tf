# フロントエンドのbaseURL
resource "aws_ssm_parameter" "base_url" {
  name = "/front/baseURL"

  # よくわからんけどbaseURLもbrouserBaseURLもドメイン名じゃないと接続できなかった
  value = "https://www.hirabayashi.work:3000"
  type = "String"
  description = "フロントエンドのbaseURL"

  lifecycle {
    ignore_changes = [value]
  }
}

# フロントエンドのbrouserBaseURL
resource "aws_ssm_parameter" "browser_base_url" {
  name = "/front/browserBaseURL"

  value = "https://www.hirabayashi.work:3000"
  type = "String"
  description = "フロントエンドのbaseURL"

  lifecycle {
    ignore_changes = [value]
  }
}

# フロントエンドのserverMiddlewareのurl
resource "aws_ssm_parameter" "server_middleware_url" {
  name = "/front/serverMiddlewareUrl"

  value = "https://www.hirabayashi.work:443"
  type = "String"
  description = "フロントエンドのserverMiddlewareUrl"

  lifecycle {
    ignore_changes = [value]
  }
}

# railsのマスターキー
resource "aws_ssm_parameter" "rails_master_key" {
  name = "/web/rails-master-key"
  value = "master-key"
  type = "SecureString"
  description = "railsのマスターキー"

  lifecycle {
    ignore_changes = [value]
  }
}