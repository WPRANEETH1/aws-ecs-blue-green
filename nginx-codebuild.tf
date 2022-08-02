resource "aws_iam_role" "code-build-bg" {
  name = "ecs-code-build-bg-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.code-build-bg.name
}

resource "aws_iam_role_policy_attachment" "amazon-codecommit-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
  role       = aws_iam_role.code-build-bg.name
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-container-reg-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.code-build-bg.name
}

resource "aws_iam_role_policy_attachment" "amazon-s3-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.code-build-bg.name
}

resource "aws_iam_role_policy_attachment" "amazon-cloudwatch-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.code-build-bg.name
}

resource "aws_iam_role_policy_attachment" "amazon-codebuild-admin-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.code-build-bg.name
}

resource "aws_iam_role_policy_attachment" "amazon-ecs-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.code-build-bg.name
}

resource "aws_s3_bucket" "nginx_codebuild_bg_bucket" {
  bucket = "nginx-codebuild-bg-bucket"
}

resource "aws_s3_bucket_acl" "codebuild_bucket_bg_acl" {
  bucket = aws_s3_bucket.nginx_codebuild_bg_bucket.id
  acl    = "private"
}

resource "aws_security_group" "nginx_codebuild_bg" {
  name   = "nginx-codebuild-${var.environment}-bg-gs"
  vpc_id = aws_vpc.main.id

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_codebuild_project" "ecs_to_ecr_bg" {
  name          = "nginx-ecr-codebuild-bg"
  description   = "nginx_codebuild_project"
  build_timeout = "60"
  service_role  = aws_iam_role.code-build-bg.arn

  artifacts {
    location = aws_s3_bucket.nginx_codebuild_bg_bucket.bucket
    type     = "S3"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "task_definition"
      value = aws_ecs_task_definition.nginx_bg.family
    }  

    environment_variable {
      name  = "container_name"
      value = "nginx"
    }  
    
    environment_variable {
      name  = "container_port"
      value = 80
    }       

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "NO_SOURCE"
    buildspec       = "${file("nginx-docker/buildspec.yml")}"
  }

  source_version = "main"

  vpc_config {
    vpc_id = aws_vpc.main.id

    subnets = [
      aws_subnet.private.0.id,
      aws_subnet.private.1.id
    ]

    security_group_ids = ["${aws_security_group.nginx_codebuild_bg.id}"]
  }

  tags = {
    Environment = "Test"
  }
}