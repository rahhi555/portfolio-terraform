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

# フロントエンドで使用するActionCableエンドポイント
resource "aws_ssm_parameter" "action_cable_url" {
  name = "/front/actionCableUrl"
  value = "wss://www.hirabayashi.work:3000/cable"
  type = "String"
  description = "フロントエンドのアクションケーブルURL"

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

# GoogleMapsApiキー
resource "aws_ssm_parameter" "google_maps_api_key" {
  name = "/front/googleMapsApiKey"
  value = "google maps api key"
  type = "SecureString"
  description = "google maps apiのキー"
}