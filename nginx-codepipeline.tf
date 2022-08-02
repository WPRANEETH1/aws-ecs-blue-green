

resource "aws_codepipeline" "ecs_codepipeline_bg" {
  name     = "nginx-pipeline-bg"
  role_arn = aws_iam_role.ecs_codepipeline_bg_role.arn

  artifact_store {
    location = aws_s3_bucket.nginx_codepipeline_bg_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "ImagePush"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["Image"]

      configuration = {
        RepositoryName = aws_ecr_repository.nginx_bg.name
        ImageTag     = "latest"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Image"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ecs_to_ecr_bg.name
        PrimarySource = "SourceArtifact"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ApplicationName = aws_codedeploy_app.codedeploy_nginx.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dgpecr_codedeploy_nginx.deployment_group_name
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath = "taskdef.json"
        AppSpecTemplateArtifact = "BuildArtifact"
        AppSpecTemplatePath = "appspec.yaml"
        Image1ArtifactName = "BuildArtifact"
        Image1ContainerName = "IMAGE1_NAME"
      }
    }
  }
}

resource "aws_s3_bucket" "nginx_codepipeline_bg_bucket" {
  bucket = "nginx-codepipeline-bg-bucket"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_bg_acl" {
  bucket = aws_s3_bucket.nginx_codepipeline_bg_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "ecs_codepipeline_bg_role" {
  name = "nginx-codepipeline-bg-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazon-s3-full-codepipeline-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ecs_codepipeline_bg_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-cloudwatch-full-codepipeline-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.ecs_codepipeline_bg_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-codecommit-full-codepipeline-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
  role       = aws_iam_role.ecs_codepipeline_bg_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-codepipeline-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
  role       = aws_iam_role.ecs_codepipeline_bg_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-codebuild-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.ecs_codepipeline_bg_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-ecs-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.ecs_codepipeline_bg_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-ecsreg-full-bg-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.ecs_codepipeline_bg_role.name
}