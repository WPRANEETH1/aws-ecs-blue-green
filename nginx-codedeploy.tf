resource "aws_codedeploy_app" "codedeploy_nginx" {
  compute_platform = "ECS"
  name             = "nginx-docker-codedeploy-bg"
}

resource "aws_codedeploy_deployment_group" "dgpecr_codedeploy_nginx" {
  app_name               = aws_codedeploy_app.codedeploy_nginx.name
  deployment_group_name  = "dgpecr-nginx-test-codedeploy-bg"
  service_role_arn       = aws_iam_role.ecs_codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {    
    enabled = true    
    events = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  blue_green_deployment_config {

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = "0"
    }
    
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = "5"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # Configuration block(s) of the ECS services for a deployment group.
  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.nginx_bg.name
  }

  load_balancer_info {   

    target_group_pair_info {    
      prod_traffic_route {
        listener_arns = [aws_alb_listener.blue_listener.arn]
      }
    
      target_group {
        name = aws_alb_target_group.blue.name
      }

      target_group {
        name = aws_alb_target_group.green.name
      }
      
      test_traffic_route {
        listener_arns = [aws_alb_listener.green_listener.arn]
      }
    }
  }
}

resource "aws_iam_role" "ecs_codedeploy_role" {
  name = "nginx-codedeploy-bg-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazon-codedeploy-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.ecs_codedeploy_role.name
}