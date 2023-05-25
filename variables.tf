variable "aws_access_key" {
  type    = string
  default = ""
}

variable "aws_access_secret" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "target_vpc_id" {
  type    = string
  default = ""
}

variable "keypair_name" {
  type    = string
  default = ""
}

variable "mysql_admin_user" {
  type    = string
  default = ""
}

variable "mysql_admin_password" {
  type    = string
  default = ""
}

variable "s3_bucket_name" {
  type    = string
  default = "gtp-uat-app"
}

variable "tls_common_name" {
  type    = string
  default = ""
}

variable "tls_organization" {
  type    = string
  default = ""
}

variable "tls_organizational_unit" {
  type    = string
  default = ""
}

variable "tls_country" {
  type    = string
  default = ""
}
