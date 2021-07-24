# カスタマーマスターキーの定義
resource "aws_kms_key" "svg_portfolio" {
  # 説明
  description = "svg_portfolio Customer Master Key"
  # 自動ローテーション機能を有効にする。
  enable_key_rotation = true
}

# カスタマーマスターキーのUUIDのエイリアス定義
resource "aws_kms_alias" "svg_portfolio" {
  # エイリアスの表示名。名前は[alias」という単語で始まり、その後にスラッシュ（alias /）が続く必要がある
  name = "alias/svg_portfolio"
  target_key_id = aws_kms_key.svg_portfolio.key_id
}

