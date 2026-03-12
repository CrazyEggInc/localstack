resource "aws_iam_role" "localstack_codebuild" {
  name = "localstack-codebuild"

  assume_role_policy = <<-EOF
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

  count = terraform.workspace == "production" ? 1 : 0
}

resource "aws_iam_role_policy" "localstack_codebuild_policy" {
  role = aws_iam_role.localstack_codebuild[count.index].name

  policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:logs:${local.workspace["region"]}:173509387151:log-group:/aws/codebuild/localstack",
                    "arn:aws:logs:${local.workspace["region"]}:173509387151:log-group:/aws/codebuild/localstack:*"
                ],
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "codebuild:CreateReportGroup",
                    "codebuild:CreateReport",
                    "codebuild:UpdateReport",
                    "codebuild:BatchPutTestCases",
                    "codebuild:BatchPutCodeCoverages"
                ],
                "Resource": [
                    "arn:aws:codebuild:${local.workspace["region"]}:173509387151:report-group/localstack-*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "secretsmanager:GetSecretValue"
                ],
                "Resource": [
                    "arn:aws:secretsmanager:${local.workspace["region"]}:173509387151:secret:CodeBuild*"
                ]
            }
        ]
    }
  POLICY

  count = terraform.workspace == "production" ? 1 : 0
}

resource "aws_iam_role_policy_attachment" "localstack_codebuild_ecr" {
  role       = aws_iam_role.localstack_codebuild[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  count      = terraform.workspace == "production" ? 1 : 0
}

resource "aws_codebuild_project" "localstack" {
  name          = "localstack"
  description   = "Build localstack docker images"
  build_timeout = "20"
  service_role  = aws_iam_role.localstack_codebuild[count.index].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }

    environment_variable {
      name  = "AWS_REGION"
      value = "us-east-1"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "173509387151"
    }

    environment_variable {
      name  = "DOCKER_HUB_TOKEN"
      value = "CodeBuild:DOCKER_HUB_TOKEN"
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "GHCR_USERNAME"
      value = "CodeBuild:GHCR_USERNAME"
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "GHCR_TOKEN"
      value = "CodeBuild:GHCR_TOKEN"
      type  = "SECRETS_MANAGER"
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/CrazyEggInc/localstack.git"
    git_clone_depth = 1
    buildspec       = ".aws/codebuild.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }

  tags  = local.workspace["default_aws_tags"]
  count = terraform.workspace == "production" ? 1 : 0
}

resource "aws_ecr_repository" "localstack" {
  name                 = "localstack"
  image_tag_mutability = "MUTABLE"
  tags                 = local.workspace["default_aws_tags"]
  count                = terraform.workspace == "production" ? 1 : 0
}
