resource "aws_ecs_service" "nginx_bg" {
  name                               = "nginx-service-${var.environment}-bg"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.nginx_bg.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = compact(concat(tolist([aws_security_group.nginx_tasks.id])))
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  deployment_controller {
      type = "CODE_DEPLOY"
  }  

  load_balancer {
    target_group_arn = aws_alb_target_group.blue.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [
    aws_alb_listener.green_listener,
  ]  

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}