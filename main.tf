provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret

  default_tags {
    tags = {
      Environment = "UAT"
      Name        = "GTP"
      CreatedBy   = "ACE/Silverstream/DataSpeed"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

##################
# Launch template
##################

data "aws_key_pair" "deployer" {
  key_name = var.keypair_name
}

resource "aws_launch_configuration" "gtp_uat_app" {
  name_prefix                 = "gtp-uat-auto-scaling-"
  image_id                    = "ami-04ba270ccd8098407" # Red Hat Enterprise Linux 9 (HVM), SSD Volume Type x86_64
  instance_type               = "t2.small"              # Real UAT: c5.xlarge
  security_groups             = [aws_security_group.gtp_uat_app_instance.id]
  key_name                    = data.aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.gtp_uat_ec2_instance_profile.name

  user_data = base64encode("${templatefile("${path.module}/user-data-app.sh", {
    AWS_CLOUDWATCH_ACCESS_KEY_ID = var.aws_access_key
    AWS_CLOUDWATCH_SECRET_ACCESS = var.aws_access_secret
    AWS_S3_BUCKET_NAME           = var.s3_bucket_name
    TLS_COMMON_NAME              = var.tls_common_name
    TLS_ORGANIZATIONAL_UNIT      = var.tls_organizational_unit
    TLS_ORGANIZATION             = var.tls_organization
    TLS_COUNTRY                  = var.tls_country
  })}")

  lifecycle {
    create_before_destroy = true
  }
}

##################
# Auto scaling
##################

resource "aws_autoscaling_group" "gtp_uat_app" {
  name_prefix          = "gtp-uat-app-"
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.gtp_uat_app.name
  vpc_zone_identifier  = [data.aws_subnets.public.ids[0], data.aws_subnets.public.ids[1]]

  tag {
    key                 = "Name"
    value               = "gtp-uat-app (autoscaling)"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Application"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "UAT"
    propagate_at_launch = true
  }

  tag {
    key                 = "CodeDeploy"
    value               = "gtp-uat-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Snapshot"
    value               = "true"
    propagate_at_launch = true
  }

}

resource "aws_s3_object" "object" {
  bucket = var.s3_bucket_name
  key    = "configs/deployed_flag"
  source = "deployed_flag"
}
