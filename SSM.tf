# データベースの暗号化されたパスワード
resource "aws_ssm_parameter" "db_raw_password" {
  name = "/db/raw/password"
  # 暗号化する値がソースコードに平分で書かれてしまうので、デフォルトに適当な値を入力しておき、
  # 後でAWS CLIから変更する手法を取る(絶対にパスワードの変更を忘れないこと！)
  value = "password"
  type = "SecureString"
  description = "データベースのパスワード"

  # 手動で変更かけた後にterraform applyして戻らないようにする
  lifecycle {
    ignore_changes = [value]
  }
}

# データベースのホスト名
resource "aws_ssm_parameter" "db_raw_hostname" {
  name = "/db/hostname"

  value = aws_db_instance.hair_salon_bayashi.address
  type = "String"
  description = "データベースのホスト名"

  lifecycle {
    ignore_changes = [value]
  }
}

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

# バックエンドで使用するcors用のフロントurl
# フロントエンドのbrouserBaseURL
resource "aws_ssm_parameter" "front_url" {
  name = "/web/front-url"

  value = "https://www.hirabayashi.work"
  type = "String"
  description = "cors対策"

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