# aws-ecs-blue-green

Herewith `terraform` for the ECS code deployment and `blue green` steps. This Codepipeline support to trigger pipeline once you `push the image into ECR`. So I developed terraform that its included `dynamically generate the task definition and appspec file`. This means that if your infrastructure is managed by Terraform, any changes to the task definition, CodePipeline will always get the latest information. In this repository, I will cover how I have approached it.

![text](/nginx-docker/blue-green.PNG)
#

## Steps CodePipeline works

We can trigger CodePipleine in multiple ways, the most common are:

+ Pipeline trigger, 
+ where it change in CodeCommit branch,
+ Manual Click 


Pre-requisite
+ ECR with images
+ ECS Cluster (blue green)

## Source
    We need to mentioned the `ECR` image to define the CodePipeline to deploy at the end. Codepipeline will pull the image tag via the `#256`
![text](/nginx-docker/source.PNG)  

## Build
    CodeBuild will generate the taskdef.json and appspec.yaml dynamically. The appspec.yaml define the version of task definition it used in deployment. So below CodeBuild represent the way how to extrace the details on existing ECS deployment.

![text](/nginx-docker/build.PNG)

```
version: 0.2
phases:
  build:
    commands:
      - "printf 'version: 0.0\nResources:\n  - TargetService:\n      Type: AWS::ECS::Service\n      Properties:\n        TaskDefinition: <TASK_DEFINITION>\n        LoadBalancerInfo:\n          ContainerName: \"%s\"\n          ContainerPort: %s' ${container_name} ${container_port} > appspec.yaml"
      - aws ecs describe-task-definition --output json --task-definition ${task_definition} --query taskDefinition > template.json
      - jq '.containerDefinitions | map((select(.name == "'${container_name}'") | .image) |= "<IMAGE1_NAME>") | {"containerDefinitions":.}' template.json  > template2.json
      - jq -s '.[0] * .[1]' template.json template2.json > taskdef.json
artifacts:
  files:
    - imageDetail.json
    - appspec.yaml
    - taskdef.json
```    

Deploy
    To proceed with deployment in CodeDeploy it required these 3 files (imageDetail, appspec and taskdef). For BlueGreen deployment, you need to provide a load balancer with 2 target groups, So ALB for more flexibility.
[[https://github.com/WPRANEETH1/aws-ecs-blue-green/blob/master/nginx-docker/deploy.PNG]]


CodePipeline
```
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
``` 
