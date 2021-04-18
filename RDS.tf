# DBのセキュリティーグループ
module "mysql_sg" {
  source = "./security_group"
  name = "mysql-sg"
  vpc_id = aws_vpc.hair_salon_bayashi.id
  # DB側のportと合わせる
  port = 3306
  # vpc内のみでの通信のため、インバウンドルールのcidr_blockはvpcのものを指定する
  cidr_blocks = [aws_vpc.hair_salon_bayashi.cidr_block]
}

# DBパラメータグループの定義
resource "aws_db_parameter_group" "hair_salon_bayashi" {
  name = "hair-salon-bayashi"
  family = "mysql8.0"

  parameter {
    name = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name = "character_set_server"
    value = "utf8mb4"
  }
}

# DBオプショングループの定義
resource "aws_db_option_group" "hair_salon_bayashi" {
  name = "hair-salon-bayashi"
  engine_name = "mysql"
  major_engine_version = "8.0"
}

# DBサブネットグループの定義
resource "aws_db_subnet_group" "hair_salon_bayashi" {
  name = "hair_salon_bayashi"
  # サブネット最低２つ必要。なのでvpc.tfであらかじめ２つは作っておくこと
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_other.id]
}

resource "aws_db_instance" "hair_salon_bayashi" {
  # データベースの識別子
  identifier = "hair-salon-bayashi"
  engine = "mysql"
  engine_version = "8.0.23"
  instance_class = "db.t3.micro"
  # 最大ストレージ容量。最低は20Gib
  allocated_storage = 20
  # allocated_storageの容量がオーバーした時に自動的にスケールする容量
  max_allocated_storage = 100
  storage_type = "gp2"
  # 暗号化
  storage_encrypted = true
  # 暗号化に使用する鍵。自分で作成したKMSの鍵を使って暗号化する。
  kms_key_id = aws_kms_key.hair_salon_bayashi.arn
  username = "root"
  # 初期状態のパスワード。DB起動後すぐに変更する。
  password = "password"
  # マルチAZを有効にする(サブネットグループの定義で異なるAZのサブネットを指定することが前提)
  multi_az = false
  # VPC外からのアクセスを許可する
  publicly_accessible = false
  # 自動的にDBをアップグレードするか。
  auto_minor_version_upgrade = false
  # 削除する際にスナップショットを作成しない
  skip_final_snapshot = true
  port = 3306
  vpc_security_group_ids = [module.mysql_sg.security_group_id]
  parameter_group_name = aws_db_parameter_group.hair_salon_bayashi.name
  option_group_name = aws_db_option_group.hair_salon_bayashi.name
  db_subnet_group_name = aws_db_subnet_group.hair_salon_bayashi.name

  # 手動でパスワードを変更した後、terraform applyしてもソースコードのパスワードに戻らないようにする
  lifecycle {
    ignore_changes = [password]
  }
}