resource "aws_codepipeline" "codepipeline" {
  artifact_store {
    location = "${aws_s3_bucket.build-bucket.bucket}"
    type     = "S3"
  }

  role_arn = "${aws_iam_role.simple-codepipeline-role.arn}"
  name     = "simple-${var.project_name}"

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "ThirdParty"
      provider = "GitHub"
      version  = "1"

      output_artifacts = [
        "build",
      ]

      configuration {
        Owner  = "${var.github__owner}"
        Repo   = "${var.github__repo}"
        Branch = "${var.github__branch}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"

      input_artifacts = [
        "build",
      ]

      output_artifacts = ["deployables"]

      version = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.simple-cicd.name}"
      }
    }
  }

  stage = {
    name = "Deploy"

    action {
      name     = "Deploy"
      owner    = "AWS"
      provider = "S3"
      version  = "1"
      category = "Deploy"

      input_artifacts = [
        "deployables",
      ]

      configuration {
        BucketName = "${aws_s3_bucket.deploy-bucket.bucket}"
        Extract    = "true"
      }
    }

    action {
      name     = "invalidateCache"
      owner    = "AWS"
      provider = "Lambda"
      version  = "1"
      category = "Invoke"

      configuration {
        FunctionName   = "${aws_lambda_function.invalidate-cache.function_name}"
        UserParameters = "${aws_cloudfront_distribution.website.id}"
      }
    }

    /*

     stage.2.action.#:                              "2" => "1"
      stage.2.action.1.category:                     "Invoke" => ""
      stage.2.action.1.configuration.%:              "2" => "0"
      stage.2.action.1.configuration.FunctionName:   "invalidateCache" => ""
      stage.2.action.1.configuration.UserParameters: "ASDFASDF" => ""
      stage.2.action.1.name:                         "invalidateCache" => ""
      stage.2.action.1.owner:                        "AWS" => ""
      stage.2.action.1.provider:                     "Lambda" => ""
      stage.2.action.1.version:                      "1" => ""

*/
  }
}

resource "aws_s3_bucket" "build-bucket" {
  bucket = "codepipeline-${var.project_name}"
  acl    = "private"
}

resource "aws_s3_bucket" "deploy-bucket" {
  bucket = "deploy-${var.project_name}"
  acl    = "private"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::deploy-timesteward/*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "simple-codepipeline-role" {
  name = "simple-codepipeline-role-${var.project_name}"

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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.simple-codepipeline-role.id}"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}
