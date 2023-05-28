########
# IAM 
########

# IAM for Codedeploy
#####################

resource "aws_iam_role" "gtp_uat_app_codedeploy_service" {
  name = "CodeDeploy-Service-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = aws_iam_role.gtp_uat_app_codedeploy_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# IAM for ec2
#############

data "aws_iam_policy_document" "gtp_uat_ec2_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gtp_uat_ec2_role" {
  name               = "CodeDeploy-EC2-Instance-Profile"
  assume_role_policy = data.aws_iam_policy_document.gtp_uat_ec2_role.json
}

# IAM for s3
#############

resource "aws_iam_role_policy" "gtp_uat_ec2_role" {
  name = "CodeDeploy-EC2-Permissions"
  role = aws_iam_role.gtp_uat_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gtp_uat_cloudwatch_instance_profile" {
  role       = aws_iam_role.gtp_uat_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "gtp_uat_ssm_instance_profile" {
  role       = aws_iam_role.gtp_uat_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "gtp_uat_codedeploy_instance_profile" {
  role       = aws_iam_role.gtp_uat_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# the instance profile will be attached to EC2 instance to allow CodeDeploy. See aws_launch_configuration.
resource "aws_iam_instance_profile" "gtp_uat_ec2_instance_profile" {
  name = "CodeDeploy-EC2-Instance-Profile"
  role = aws_iam_role.gtp_uat_ec2_role.name
}

# IAM for DLM
#############

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "dlm-lifecycle-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "dlm_lifecycle" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "gtp-uat-app-dlm-lifecycle-policy"
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy = data.aws_iam_policy_document.dlm_lifecycle.json
}
