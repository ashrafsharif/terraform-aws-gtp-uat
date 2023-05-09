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

variable "keypair" {
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
