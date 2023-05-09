######
# VPC
######

# Specify the target VPC here. Change the filter values (for tag:Name) accordingly for precise subnet lookups

data "aws_vpc" "target_vpc" {
  id = "vpc-0ff57649c483b7635"
}

data "aws_subnets" "public" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.target_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["dev-tpp-acegold-public-az*"]
  }

}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.target_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["dev-tpp-acegold-private-az*"]
  }
}

data "aws_subnets" "protected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.target_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["dev-tpp-acegold-protected-az*"]
  }
}
