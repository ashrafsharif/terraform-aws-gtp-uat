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

4) Specify the required values in the following files and lines:

  4.1) AWS access key and secret - `terraform.tfvars` on line 1 to 6 (the account should have all the AWS privileges):
  
  ```ruby
  aws_access_key       = "AKIAJ..."
  aws_access_secret    = "wvXTg..."
  target_vpc_id        = "vpc-0ff57649c483b7635"
  keypair              = "my-keypair"
  mysql_admin_user     = "gtp_db_admin"
  mysql_admin_password = "mySuperSecretP455"
  ```
  
  4.2) AWS CloudWatch access key and secret - `user-data-app.sh` on line 6 & 7 (you may use the same value as specified at 4.1):
  
  ```bash
  AWS_CLOUDWATCH_ACCESS_KEY_ID=''
  AWS_CLOUDWATCH_SECRET_ACCESS=''
  ```
  
5) Create a private S3 bucket (if no exists) named `gtp-uat-app`. Use your AWS Management Console.

6) Upload the following files (this will be provided separately):

```
$ tree
.
├── configs
│   ├── config.ini
│   ├── gtp.conf
│   ├── nginx.conf
│   └── ngx_nchan_module_nginx1.24.0_rhel9_04ba270ccd8098407.tar.gz
├── gtp-db.tar.gz
└── gtp.zip
```

*** The above has 1 directory called `configs`, 4 files under that directory, and 2 more files on the parent directory, `gtp-db.tar.gz` (db schema) and `gtp.zip` (app).

6) Under the `terraform-aws-gtp-uat` directory, initialize Terraform modules:

```
terraform init
```

7) Start the deployment:

```
terraform plan # make sure no error in the planning stage
terraform apply # type 'yes' in the prompt
```

## Testing 

1) You shall see the following output after the Terraform deployment completes:

```ruby
app_endpoint = "gtp-uat-app-lb-2144828538.ap-southeast-1.elb.amazonaws.com"
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

2) Open your browser and go to the `app_endpoint` on HTTPS (http is no longer supported), for example: `https://gtp-uat-app-lb-2144828538.ap-southeast-1.elb.amazonaws.com/`. You shall see an error on Redis, which is correct because we haven't configured Redis endpoint yet. This indicates the ASG and ELB are working, plus php-fpm and nginx. The sample app is staged from `gtp-uat-app` S3 bucket.

3) Before testing MySQL connectivity, create the MySQL database, user and password manually. SSH to the EC2 instance and run the following commands:

```bash
$ mysql -u {mysql-admin-user} -p -h {rds_endpoint_value_without_port} -P 3306
mysql> CREATE DATABASE gtp;
mysql> CREATE USER 'gtp'@'172.31.%.%' IDENTIFIED BY 'pass098TT';
mysql> GRANT ALL PRIVILEGES ON gtp.* TO 'gtp'@'172.31.%.%';

$ cd /usr/local/nginx/html/
$ tar -xzf gtp-db.tar.gz
$ sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i db_schema.sql
$ mysql -f -ugtp -p -h gtpuatmysql.cdw9q2wnb00s.ap-southeast-1.rds.amazonaws.com gtp < db_schema.sql
$ mysql -f -ugtp -p -h gtpuatmysql.cdw9q2wnb00s.ap-southeast-1.rds.amazonaws.com gtp < db_data.sql
```

4) To test MySQL and Redis, you have to update the following file `/usr/local/nginx/html/gtp/source/snapapp_otc/config.ini` and specify the values on line 3 to 8 accordingly:

```ruby
snap.db.host = gtpuatmysql.cdw9q2wnb00s.ap-southeast-1.rds.amazonaws.com:3306
snap.db.username = gtp
snap.db.password = pass098TT
snap.cache.servers = gtp-uat-redis.u2yh4k.0001.apse1.cache.amazonaws.com:6379
```

5) Save the file and you should be able to access `https://gtp-uat-app-lb-2144828538.ap-southeast-1.elb.amazonaws.com`. You should be able to access the application.

## Destroy

1) To destroy everything:

```
terraform destroy # type 'yes' in the prompt
```

Note that it won't destroy the existing VPC's resources including subnets, route table, gateway, etc.

## Changelogs

#### Version 0.1 - 9th May 2023 - branch 0.1 (master)

* First push
* Assuming deployment on existing VPC
