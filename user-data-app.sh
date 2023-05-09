#!/bin/bash

# user-data-app.sh - provision app server for GTP

## Specify access key ID and secret to export logs to CloudWatch
AWS_CLOUDWATCH_ACCESS_KEY_ID=''
AWS_CLOUDWATCH_SECRET_ACCESS=''

## The following steps are for RHEL 9
## -- start --
## ami-04ba270ccd8098407 - RHEL 9 - ap-southeast-1 (owner: amazon)

# set SELinux to permissive
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

# configure epel, nginx, remi for php & redis
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo curl -o /etc/yum.repos.d/nginx.repo https://gist.githubusercontent.com/ashrafsharif/bda57ea4e31085be37fe8c80ac98452e/raw/d6ead6e1e7cbef409f858fd34dcdb382e2278f0a/nginx.repo
sudo dnf config-manager --set-enabled nginx-mainline
sudo dnf config-manager --set-enabled remi

# install php8.2, nginx 1.24 (must use 1.24 due to RHEL using OpenSSL 3.0) and dependencies
# install php7.4 - gtp2 does not support 8.2 yet
sudo dnf -y module switch-to php:remi-7.4
sudo dnf -y install openssl git vim wget ruby curl sysstat net-tools bind-utils mysql redis unzip lynx \
    php-common php php-pecl-translit php-mbstring php-pecl-zip php-json \
    php-pecl-mcrypt php-pecl-memcache php-opcache php-xml php-phpiredis php-memcached \
    php-pecl-ssh2 php-devel php-mysqlnd php-pecl-http php-bcmath php-pecl-igbinary php-pecl-raphf \
    php-cli php-gd php-xmlrpc php-pecl-redis5 php-pdo php-pecl-msgpack php-fpm \
    nginx

# install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# configure php-fpm
sed -i.ori 's/^listen =.*/listen = 127.0.0.1:9000/g' /etc/php-fpm.d/www.conf
sed -i 's/^user =.*/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/^group =.*/group = nginx/g' /etc/php-fpm.d/www.conf
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
sudo touch /.user-data-app.phpfpm.complete

# configure AWS credential
mkdir -p /root/.aws/
cat >/root/.aws/credentials <<EOF
[default]
region = ap-southeast-1
aws_access_key_id = $AWS_CLOUDWATCH_ACCESS_KEY_ID
aws_secret_access_key = $AWS_CLOUDWATCH_SECRET_ACCESS
EOF
sudo chmod 600 /root/.aws/credentials

# generate ssl key and cert
sudo mkdir -p /etc/pki/nginx/private
sudo openssl req -subj '/CN=GTP/O=ACE Group/C=MY' \
    -new -newkey rsa:2048 -sha256 -keyout /etc/pki/nginx/private/server.key \
    -days 3650 -nodes -x509 -out /etc/pki/nginx/server.crt

# pull nginx configurations from S3
aws_exec=/usr/local/bin/aws
cd /etc/nginx/
sudo mv nginx.conf nginx.conf.ori
$aws_exec s3 cp s3://gtp-uat-app/configs/nginx.conf .
sudo chown root:root nginx.conf
cd /etc/nginx/conf.d/
$aws_exec s3 cp s3://gtp-uat-app/configs/gtp.conf .
rm -Rf default.conf
sudo chown root:root /etc/nginx/conf.d/gtp.conf
cd /usr/lib64/nginx/modules/
$aws_exec s3 cp s3://gtp-uat-app/configs/ngx_nchan_module_nginx1.24.0_rhel9_04ba270ccd8098407.tar.gz .
tar -xzf ngx_nchan_module_nginx1.24.0_rhel9_04ba270ccd8098407.tar.gz
mkdir -p /usr/share/nginx/modules/
cat >/usr/share/nginx/modules/mod-nchan.conf <<EOF
load_module "/usr/lib64/nginx/modules/ngx_nchan_module.so";
EOF

sudo systemctl start nginx
sudo systemctl enable nginx
sudo touch /.user-data-app.nginx.complete

# install codedeploy agent
sudo wget https://aws-codedeploy-ap-southeast-1.s3.ap-southeast-1.amazonaws.com/latest/install
sudo chmod 755 install
sudo ./install auto
sudo systemctl enable codedeploy-agent
sudo touch /.user-data-app.codedeploy.complete

# install cloudwatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
dnf -y localinstall amazon-cloudwatch-agent.rpm
sudo touch /.user-data-app.cloudwatch.complete

# nginx dir is /usr/local/nginx/html
sudo mkdir -p /usr/local/nginx/html
cd /usr/local/nginx/html/
$aws_exec s3 cp s3://gtp-uat-app/gtp.zip .
$aws_exec s3 cp s3://gtp-uat-app/gtp-db.tar.gz .
unzip gtp.zip
cd /usr/local/nginx/html/gtp/source/snapapp_otc
$aws_exec s3 cp s3://gtp-uat-app/configs/config.ini .
sudo touch /.user-data-app.git.complete
cd /usr/local/nginx/html/
rm -Rf gtp.zip __MACOSX
mkdir /usr/local/nginx/html/gtp/source/snapapp_otc/logs
touch /usr/local/nginx/html/gtp/source/snapapp_otc/logs/snap.log
chmod -Rf 777 /usr/local/nginx/html/gtp/source/snapapp_otc/logs
chown -Rf nginx:nginx gtp
sudo touch /.user-data-app.staging.complete

# create a flag file indicating deployment is complete
sudo touch /.user-data-app.all.complete

## -- end --
