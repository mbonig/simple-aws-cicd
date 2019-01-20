data "archive_file" "invalidate-cache-code" {
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/compiled/lambdas.zip"
  type        = "zip"
}

resource "aws_lambda_function" "invalidate-cache" {
  function_name    = "simple-cicd-invalidateCache"
  handler          = "invalidateCache.handler"
  filename         = "${data.archive_file.invalidate-cache-code.output_path}"
  source_code_hash = "${data.archive_file.invalidate-cache-code.output_md5}"
  role             = "${aws_iam_role.invalidate-cache-lambda-role.arn}"
  runtime          = "nodejs8.10"
}

resource "aws_iam_role" "invalidate-cache-lambda-role" {
  name = "invalidate-cache-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "cloudfront_codepipeline_lambda_access" {
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:PutJobSuccessResult",
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "cloudwatch_lambda_access" {
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-east-1:536309290949:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:536309290949:log-group:/aws/lambda/invalidateCache:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda-attachement-cw" {
  name       = "grant-lambda-to-CW"
  policy_arn = "${aws_iam_policy.cloudwatch_lambda_access.arn}"

  roles = [
    "${aws_iam_role.invalidate-cache-lambda-role.name}",
  ]
}

resource "aws_iam_policy_attachment" "lambda-attachment-cp-cf" {
  name       = "grant-lambda-to-CP-CF"
  policy_arn = "${aws_iam_policy.cloudfront_codepipeline_lambda_access.arn}"

  roles = [
    "${aws_iam_role.invalidate-cache-lambda-role.name}",
  ]
}
