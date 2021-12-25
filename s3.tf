# プライベートバケット
resource "aws_s3_bucket" "private" {
  bucket = "rahhi555-private-terraform"
  force_destroy = true
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
# プライベートバケットのアクセス制限
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

#　パブリックバケット
resource "aws_s3_bucket" "public" {
  bucket = "rahhi555-public-terraform"
  # データが残っていても削除可能
  force_destroy = true
  cors_rule {
    allowed_origins = ["https://www.minimap.work"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

#　alb(アプリケーションロードバランサー)ログバケット
resource "aws_s3_bucket" "alb_log" {
  bucket = "rahhi555-alb-log-terraform"
  acl = "private"
  force_destroy = true
  lifecycle_rule {
    enabled = true

    expiration {
      days = "7"
    }
  }
}
# alb_logバケットポリシーに使用するポリシードキュメント
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type = "AWS"
      # ここのIDはリージョンによって決まる。詳しくは下のURL
      # https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/classic/enable-access-logs.html
      identifiers = ["582318560864"]
    }
  }
}
# alb_logバケットポリシー
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}