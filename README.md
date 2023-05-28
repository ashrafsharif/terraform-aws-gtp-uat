# terraform-aws-gtp-uat

## Deployment Instructions

1) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and [git](https://github.com/git-guides/install-git) on your workstation.

2) Clone this repo into your workstation. Example on Linux:

```bash
git clone https://github.com/ashrafsharif/terraform-aws-gtp-uat
```

3) Navigate to the directory:

```bash
cd terraform-aws-gtp-uat
```

4) Create a private S3 bucket (if not exists) named `gtp-uat-app-bucket`. Use your AWS Management Console.

5) Upload the following files (this will be provided separately, `GTP-UAT-S3-0.4.zip`):

```
$ tree
.
├── configs
│   ├── amazon-cloudwatch-agent.json
│   ├── bootstrap.sh
│   ├── config.ini
│   ├── gtp.conf
│   ├── nginx.conf
│   └── ngx_nchan_module_nginx1.24.0_rhel9_04ba270ccd8098407.tar.gz
├── gtp-db.tar.gz
└── gtp.zip
```

*** The above has 1 directory called `configs` with 6 files underneath it, and 2 more files in the parent directory, `gtp-db.tar.gz` (db schema) and `gtp.zip` (app).

6) Specify the required values in `terraform.tfvars` (the AWS access account should have AWS admin privileges):
  
```ruby
aws_access_key          = "AKIAJ..."
aws_access_secret       = "wvXTg..."
target_vpc_id           = "vpc-0ff57649c483b7635"
keypair_name            = "my-keypair"
s3_bucket_name          = "gtp-uat-app-bucket"
mysql_admin_user        = "gtpdbadmin"
mysql_admin_password    = "mySuperSecretP455"
tls_common_name         = "subdomain.domain.com.my"
tls_organizational_unit = "Dev team"
tls_organization        = "ABCD Sdn Bhd"
tls_country             = "MY"
```
 

7) Under the `terraform-aws-gtp-uat` directory, initialize Terraform modules:

```
terraform init
```

8) Start the deployment:

```
terraform plan # make sure no error in the planning stage
terraform apply # type 'yes' in the prompt
```

## Testing 

1) You shall see the following output after the Terraform deployment completes:

```ruby
app_endpoint = "gtp-uat-app-lb-466289495.ap-southeast-1.elb.amazonaws.com"
app_name = "gtp-uat-app"
mysql_rds_endpoint = "gtpuatmysql.cdw9q2wnb00s.ap-southeast-1.rds.amazonaws.com:3306"
redis_endpoint = tolist([
  {
    "address" = "gtp-uat-redis.u2yh4k.0001.apse1.cache.amazonaws.com"
    "availability_zone" = "ap-southeast-1b"
    "id" = "0001"
    "outpost_arn" = ""
    "port" = 6379
  },
])
vpc_id = "vpc-0ff57649c483b7635"
```

2) Open your browser and go to the `app_endpoint` on HTTPS (http is no longer supported), for example: `https://gtp-uat-app-lb-466289495.ap-southeast-1.elb.amazonaws.com/`. You shall see an error on Redis, which is correct because we haven't configured Redis endpoint yet. This indicates the ASG and ALB are working, plus php-fpm and nginx. The sample app is staged from `gtp-uat-app-bucket` S3 bucket.

3) Get the EC2 instance public IP address from the management console and SSH to the EC2 instance (SSH user is `ec2-user`):

```bash
$ ssh -i {your_keypair_pem} ec2-user@{ec2_instance_public_ip_address}
```
* Or you could use Putty for Windows with the correct PPK.

4) Escalate as root user and run the `bootstrap.sh` script:

```bash
$ sudo -i
$ ./bootstrap.sh
```

*** If you get an error due to unfinished provisioning, wait for a couple of minutes and try again. This script should be running only after the provisioning script has finished. ***

5) The script will ask a couple of questions. Answer them all accordingly, for example:

```bash
Collecting information.. Do not enter blank values!

Enter the MySQL endpoint (without port) : gtpuatmysql.cdw9q2wnb00s.ap-southeast-1.rds.amazonaws.com
Enter the Redis endpoint (without port) : gtp-uat-redis.u2yh4k.0001.apse1.cache.amazonaws.com
Enter MySQL admin username              : gtpdbadmin
Enter MySQL admin password              : mySuperSecretP455
Enter MySQL user to create              : gtp
Enter MySQL user password for gtp : HbY6sdGbfhhsg4eC

Configuring PHPmyAdmin..
Configuring PHPRedisAdmin..
Creating DB user..
Staging MySQL database..
ERROR 1419 (HY000) at line 3181: You do not have the SUPER privilege and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)
ERROR 1419 (HY000) at line 3209: You do not have the SUPER privilege and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)
ERROR 1419 (HY000) at line 1249: You do not have the SUPER privilege and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)
ERROR 1419 (HY000) at line 1277: You do not have the SUPER privilege and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)
Configuring application to use the specified MySQL and Redis hosts..
Bootstrapping complete!

Testing application with curl..
Perfect! Application is reachable.
Bootstrapping success.
You may access the application from the load balancer endpoint.
```

*** You may ignore `ERROR 1419` generated by MySQL. It happens because RDS limits the SUPER privilege. ***

6) You should be able to access `https://gtp-uat-app-lb-466289495.ap-southeast-1.elb.amazonaws.com` and see the landing page. 

The deployment is now complete. Alternatively, you may simplify the URL by creating a DNS CNAME record and point it to the load balancer DNS name (`app_endpoint` value). For example, you would add the following in your DNS zone:

```
myapp.mydomain.com.      CNAME     500     gtp-uat-app-lb-466289495.ap-southeast-1.elb.amazonaws.com
```

You should be able to access it via https://myapp.mydomain.com after the DNS is propagated.

## Destroy

1) To destroy everything:

```
terraform destroy # type 'yes' in the prompt
```

Note that it won't destroy the existing VPC's resources including subnets, route table, gateway, etc.

## Changelogs

#### Version 0.4 - 28th May 2023 - branch 0.4 (master)

* Added new auto scaling host automatic provisioning, `user-data-app.sh`
* Tuned target group healthcheck, `alb.sh`
* Removed `elb.sh`
* Removed AWS credential file for CodeDeploy to work, `user-data-app.sh`
* Added logrotate definition, `user-data-app.sh`
* Added SSM agent, `user-data-app.sh`
* Set `HOST_COUNT` to 0 for UAT CodeDeploy, `codedeploy.tf`
* Added S3 object flags for automatic provisioning, `main.tf`

#### Version 0.3 - 25th May 2023 - branch 0.3

* Added `bootstrap.sh`
* Added `amazon-cloudwatch-agent.json`
* Added `waf.tf` - WAFv2 for ALB
* Supported more variables inside `terraform.tfvars`
* Improved `output.tf`
* Removed unused modules and providers, `versions.tf`
* Renamed `elb.tf` to `alb.tf`
* Environment data interpolation for EC2 user data, `user-data-app.sh`
* Added CloudWatch log group names for every service on EC2 instance `cloudwatch.tf`
* Fixed phpRedisAdmin issue specifically for AEC, `bootstrap.sh`
* Pinned nginx version to 1.24 from nginx-stable repo, `user-data-app.sh`

#### Version 0.2 - 11th May 2023 - branch 0.2

* Removed the hardcoded `vpc-id`

#### Version 0.1 - 9th May 2023 - branch 0.1

* First push
* Assuming deployment on existing VPC
