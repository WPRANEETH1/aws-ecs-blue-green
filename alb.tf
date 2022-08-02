resource "aws_lb" "main_bg" {
  name               = "ecs-alb-${var.environment}-bg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = compact(concat(tolist([aws_security_group.alb.id])))
  subnets            = aws_subnet.public.*.id

  enable_deletion_protection = false
}

resource "aws_alb_target_group" "blue" {
  name        = "ecs-nginx-${var.environment}-blue-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_target_group" "green" {
  name        = "ecs-nginx-${var.environment}-green-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "blue_listener" {
  load_balancer_arn = aws_lb.main_bg.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.blue.id
    type             = "forward"
  }
}

resource "aws_alb_listener" "green_listener" {
  load_balancer_arn = aws_lb.main_bg.id
  port              = 8080
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.green.id
    type             = "forward"
  }    
}

# resource "aws_alb_listener" "https" {
#   load_balancer_arn = aws_lb.main.id
#   port              = 443
#   protocol          = "HTTPS"

#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = ""

#   default_action {
#     target_group_arn = aws_alb_target_group.blue.id
#     type             = "forward"
#   }
# }