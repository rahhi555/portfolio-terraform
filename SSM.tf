# データベースの暗号化されたパスワード
resource "aws_ssm_parameter" "db_raw_password" {
  name = "/db/raw/password"
  # 暗号化する値がソースコードに平分で書かれてしまうので、デフォルトに適当な値を入力しておき、
  # 後でAWS CLIから変更する手法を取る(絶対にパスワードの変更を忘れないこと！)
  value = "password"
  type = "SecureString"
  description = "データベースのパスワード"

  # 手動で変更した後にterraform applyかけてもvalueが戻らないようにする
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

  # 手動で変更した後にterraform applyかけてもvalueが戻らないようにする
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

  # 手動で変更した後にterraform applyかけてもvalueが戻らないようにする
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

  # 手動で変更した後にterraform applyかけてもvalueが戻らないようにする
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

  # 手動で変更した後にterraform applyかけてもvalueが戻らないようにする
  lifecycle {
    ignore_changes = [value]
  }
}