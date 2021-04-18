# # ECSのバッチ処理用のタスク定義及びCloudWatchイベント設定
# resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
#   name = "/ecs-scheduled-tasks/hair_salon_bayashi"
#   retention_in_days = 180
# }

# # バッチ処理実行タスク定義
# resource "aws_ecs_task_definition" "hair_salon_bayashi_batch" {
#   family = "hair_salon_bayashi-batch"
#   cpu = "256"
#   memory = "512"
#   network_mode = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   container_definitions = file("./batch_container_definitions.json")
#   execution_role_arn = module.ecs_task_execution_role.iam_role_arn
#   # ECS ExecをするためのIAMロール(IAMロールはECS.tfで宣言済み)
#   task_role_arn = module.ecs_for_exec.iam_role_arn
# }

# # タスクを実行する権限と、タスクにIAMロールを渡す権限を付与を持っている
# # AmazonEC2ContainerServiceEventsRoleを取得する。
# data "aws_iam_policy" "ecs_events_role_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
# }

# # CloudWatchイベントIAMロールの定義
# module "ecs_events_role" {
#   source = "./iam_role"
#   name = "ecs-events"
#   identifier = "events.amazonaws.com"
#   policy = data.aws_iam_policy.ecs_events_role_policy.policy
# }

# # CloudWatchイベントルールの定義
# resource "aws_cloudwatch_event_rule" "hair_salon_bayashi_batch" {
#   name = "hair_salon_bayashi-batch"
#   description = "とても重要なバッチ処理です"
#   schedule_expression = "cron(*/2 * * * ? *)"
# }

# # CloudWatchイベントターゲットの定義
# resource "aws_cloudwatch_event_target" "hair_salon_bayashi_batch" {
#   target_id = "hair_salon_bayashi-batch"
#   rule = aws_cloudwatch_event_rule.hair_salon_bayashi_batch.name
#   role_arn = module.ecs_events_role.iam_role_arn
#   arn = aws_ecs_cluster.hair_salon_bayashi.arn

#   ecs_target {
#     launch_type = "FARGATE"
#     task_count = 1
#     platform_version = "1.4.0"
#     task_definition_arn = aws_ecs_task_definition.hair_salon_bayashi_batch.arn

#     network_configuration {
#       assign_public_ip = false
#       subnets = [aws_subnet.private_0.id]
#     }
#   }
# }
