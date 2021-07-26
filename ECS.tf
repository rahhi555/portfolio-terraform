# frontのサービスに割り当てるセキュリティーグループ
module "front_sg" {
  source = "./security_group"
  name   = "front-sg"
  vpc_id = aws_vpc.svg_portfolio.id
  port   = 80
  # vpc内のみでの通信のため、インバウンドルールのcidr_blockはvpcのものを指定する
  cidr_blocks = [aws_vpc.svg_portfolio.cidr_block]
}

# webのサービスに割り当てるRDS用のセキュリティーグループ
module "web_sg" {
  source = "./security_group"
  name   = "web-sg"
  vpc_id = aws_vpc.svg_portfolio.id
  port   = 3306
  # vpc内のみでの通信のため、インバウンドルールのcidr_blockはvpcのものを指定する
  cidr_blocks = [aws_vpc.svg_portfolio.cidr_block]
}

# 上記のセキュリティーグループにfront用のインバウンドルール追加
resource "aws_security_group_rule" "ingress_svg_portfolio_web" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.svg_portfolio.cidr_block]
  security_group_id = module.web_sg.security_group_id
}


# ECSタスク実行IAMロールを取得し、ECRの操作権限を付与できるようにする
# AmazonECSTaskExecutionRolePolicyの取得
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSタスク実行IAMロールのポリシードキュメントの定義
data "aws_iam_policy_document" "ecs_task_execution" {
  # source_json とすることで、ポリシーを継承することができる
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy
  statement {
    effect = "Allow"
    # ssm及びsecrets managerで登録したパラメータをECSの環境変数として取得できる権限。s3のファイルを取得する権限(.envファイル取得に使用する)
    actions   = ["ssm:GetParameters", "kms:Decrypt", "secretsmanager:GetSecretValue", "s3:GetObject", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

# ECSタスク実行IAMロールの定義 これをタスク定義のexecution_role_arn(タスク実行IAMロール)に記入
module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

#　タスクロール。ecs execをするためのaction4つを追加。
module "ecs_for_exec" {
  source     = "./iam_role"
  name       = "ecs-for-exec"
  identifier = "ecs-tasks.amazonaws.com"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = ""
          Effect = "Allow"
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
          ],
          Resource = "*"
        }
      ]
    }
  )
}

# ECSクラスター
resource "aws_ecs_cluster" "svg_portfolio" {
  name = "svg_portfolio"
}

# ECSタスク定義 front
resource "aws_ecs_task_definition" "svg_portfolio_front" {
  family = "svg_portfolio_front"
  cpu = "256"
  memory = "512"
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
  # ECS ExecをするためのIAMロール
  task_role_arn = module.ecs_for_exec.iam_role_arn
  # CloudWacthにログを投げるためのタスク実行時IAMロール
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
  # コンテナ定義
  container_definitions = file("./container_definitions/front.json")
}

# ECSサービス front
resource "aws_ecs_service" "svg_portfolio_front" {
  name = "svg_portfolio_service_front"
  cluster = aws_ecs_cluster.svg_portfolio.arn
  task_definition = aws_ecs_task_definition.svg_portfolio_front.arn
  desired_count = 1
  launch_type = "FARGATE"
  # FARGATEを選択したときのみ適用される。デフォルトは"LATEST"。
  platform_version = "1.4.0"
  # ヘルスチェックの猶予時間。frontはbuildとstartを実行するためかなり長めにとっておかないとヘルスチェックに失敗する。
  health_check_grace_period_seconds = 180
  # ECS Execを有効にする
  enable_execute_command = true

  # awsvpcネットワークモードの際に必要になるオプション。
  network_configuration {
    # パブリックIPを割り当てるか。下のsubnetsでパブリックサブネットを割り当てるならtrueにする。
    # プライベートサブネットを割り当てるならfalseでいいが、その場合ecrからコンテナを引っ張ってくるため
    # NAT gateway 等のエンドポイントが必要になる。
    assign_public_ip = true
    security_groups = [ module.front_sg.security_group_id ]
    subnets = [ 
      aws_subnet.public.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svg_portfolio.arn
    # コンテナ定義で設定したコンテナの名前
    container_name = "svg_portfolio_front"
    container_port = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# ECSタスク定義 web
resource "aws_ecs_task_definition" "svg_portfolio_web" {
  family = "svg_portfolio_web"
  cpu = "256"
  memory = "1024"
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
  # ECS ExecをするためのIAMロール
  task_role_arn = module.ecs_for_exec.iam_role_arn
  # CloudWacthにログを投げるためのタスク実行時IAMロール
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
  # コンテナ定義
  container_definitions = file("./container_definitions/web.json")
}

# ECSサービス web
resource "aws_ecs_service" "svg_portfolio_web" {
  name = "svg_portfolio_service_web"
  cluster = aws_ecs_cluster.svg_portfolio.arn
  task_definition = aws_ecs_task_definition.svg_portfolio_web.arn
  desired_count = 1
  launch_type = "FARGATE"
  # FARGATEを選択したときのみ適用される。デフォルトは"LATEST"。
  platform_version = "1.4.0"
  # ECS Execを有効にする
  enable_execute_command = true

  # awsvpcネットワークモードの際に必要になるオプション。
  network_configuration {
    # パブリックIPを割り当てるか。下のsubnetsでパブリックサブネットを割り当てるならtrueにする。
    # プライベートサブネットを割り当てるならfalseでいいが、その場合ecrからコンテナを引っ張ってくるため
    # NAT gateway 等のエンドポイントが必要になる。
    assign_public_ip = true
    security_groups = [ module.web_sg.security_group_id ]
    subnets = [ 
      aws_subnet.public.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svg_portfolio_api.arn
    # コンテナ定義で設定したコンテナの名前
    container_name = "svg_portfolio_web"
    container_port = 3000
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}