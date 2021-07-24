# vpc
resource "aws_vpc" "svg_portfolio" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "svg_portfolio"
  }
}

########### ここからパブリックサブネット ##########

# public subnet その１
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.svg_portfolio.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "svg_portfolio-public-subnet"
  }
}

# public subnet その２
# albは登録時に異なるアベイラビリティーゾーンのサブネットを２つ以上求められるため
# 登録のためだけに用意するダミーのサブネット
resource "aws_subnet" "public_other" {
  vpc_id = aws_vpc.svg_portfolio.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "svg_portfolio-public-dammy-subnet"
  }
}

# internet_gateway
resource "aws_internet_gateway" "svg_portfolio" {
  vpc_id = aws_vpc.svg_portfolio.id

  tags = {
    Name = "svg_portfolio-gateway"
  }
}

# public route_table VPC内通信のルートであるローカルルートは自動生成される。
# public_otherも同じルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.svg_portfolio.id

  tags = {
    Name = "svg_portfolio-public-route-table"
  }
}

# route_tableに追加するルート。VPC内以外の、インターネットへデータを流すためのルートを作成(デフォルトルート)
resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  gateway_id = aws_internet_gateway.svg_portfolio.id
  destination_cidr_block = "0.0.0.0/0"
}

# ルートテーブルとサブネットの関連付け
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ルートテーブルとサブネットの関連付け(ダミー用)。

resource "aws_route_table_association" "public_other" {
  subnet_id = aws_subnet.public_other.id
  route_table_id = aws_route_table.public.id
}

########## ここからプライベートサブネット ##########

# private subnet
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.svg_portfolio.id
  cidr_block = "10.0.65.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "svg_portfolio-private-subnet"
  }
}

# private subnet その２
resource "aws_subnet" "private_other" {
  vpc_id = aws_vpc.svg_portfolio.id
  cidr_block = "10.0.66.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "svg_portfolio-private-other-subnet"
  }
}

# private route_table ローカル内のみの通信なので、ルートテーブルのみの定義でおｋ
# (ローカルのルートはルートテーブルを定義すると自動で追加される)
# public_otherも同じルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.svg_portfolio.id

  tags = {
    Name = "svg_portfolio-private-route-table"
  }
}

# ルートテーブルとサブネットの関連付け
resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ルートテーブルとサブネットの関連付け ダミー用
resource "aws_route_table_association" "private_other" {
  subnet_id = aws_subnet.private_other.id
  route_table_id = aws_route_table.private.id
}