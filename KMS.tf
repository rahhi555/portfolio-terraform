# カスタマーマスターキーの定義
resource "aws_kms_key" "hair_salon_bayashi" {
  # 説明
  description = "hair_salon_bayashi Customer Master Key"
  # 自動ローテーション機能を有効にする。
  enable_key_rotation = true
}

# カスタマーマスターキーのUUIDのエイリアス定義
resource "aws_kms_alias" "hair_salon_bayashi" {
  # エイリアスの表示名。名前は[alias」という単語で始まり、その後にスラッシュ（alias /）が続く必要がある
  name = "alias/hair_salon_bayashi"
  target_key_id = aws_kms_key.hair_salon_bayashi.key_id
}

