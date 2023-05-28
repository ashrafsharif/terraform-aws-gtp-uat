#!/bin/bash
# user-data-app.sh - provision app server for GTP

## The following steps are for ami-04ba270ccd8098407 - RHEL 9 - ap-southeast-1 (owner: amazon)
## -- start --

# set SELinux to permissive
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

# configure epel, nginx & remi repositories
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo curl -o /etc/yum.repos.d/nginx.repo https://gist.githubusercontent.com/ashrafsharif/bda57ea4e31085be37fe8c80ac98452e/raw/d6ead6e1e7cbef409f858fd34dcdb382e2278f0a/nginx.repo
sudo dnf config-manager --set-enabled nginx-stable
sudo dnf config-manager --set-enabled remi

# install dependenices. nginx must be locked to 1.24 for nchan module to work, unless recompile
sudo dnf -y versionlock add nginx-1:1.24.0
sudo dnf -y module switch-to php:remi-7.4
sudo dnf -y install openssl git vim wget ruby curl sysstat net-tools bind-utils mysql redis unzip lynx nano \
    php-common php php-pecl-translit php-mbstring php-pecl-zip php-json \
    php-pecl-mcrypt php-pecl-memcache php-opcache php-xml php-phpiredis php-memcached \
    php-pecl-ssh2 php-devel php-mysqlnd php-pecl-http php-bcmath php-pecl-igbinary php-pecl-raphf \
    php-cli php-gd php-xmlrpc php-pecl-redis5 php-pdo php-pecl-msgpack php-fpm \
    nginx

# install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# create user
sudo groupadd netsite
sudo useradd -m siteadm
sudo usermod -a -G netsite siteadm
sudo mkdir /home/siteadm/.ssh
cat >/home/siteadm/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCl+k/es8DPRcYhQdfy8fYNdIqwhblNIb/eaizvht5flmPX+HEpYnur85J5vyBPyHpkj7DA242RmnlPyn5e75EvukOolexzvNLwh8FAw7QG47f92Tv48Ce3CSPdxSkgVtrSgCJQ/gUX6nTkVL3VGNfQd/YwiEDKTc4UDantpZkNDro8MuXndN7qUXE3Z/YfZ4hUFstms23TXCOvz2r/89geOJfkkYJkGS6L0j5vzwqYGWu46l1WOikFBoHkq8C7YxTRKMu/yi6An9gipA5ydjyCtQxt7cwDVpcYXWiP7xO/KK/Cn5X8cTNmCt+aXUFX8FTdjc+oHwjXm5q1S/uMAgZKY6FK4Lk44MWEkaH+tDC/qyUgF8Zt3jxozBWpOWMqdg781SQAMR2twO34D/XkxD6vJwNYdZS/SO+vaWDVxpzhuqwX0F+j3qDg2O0G9k38kjyzNgcBXXLfXQ9X1J2pF4VXhXaKlQ9IGNpviq39LeJSUS0LDCyqARngk+1alsGEl1e1wJBlnLY+ddFSPB7DzItecTuuudRFzOiQ074QDRSjQvRSGrKcddQMnvvH3e/vj/1jfybLitDoeIVpXBZ0vFz3zmn9eG9LpLOO74N56MdJy0Mg2MKAS+8lPasMhbH4fjnyJ4/itceAENYXfyYtGo8v9wX1MYDPkV8HzLoLQVo0rQ== developers@silverstream.my
EOF
sudo chown -Rf siteadm:netsite /home/siteadm/.ssh
sudo chmod 700 /home/siteadm/.ssh
sudo chmod 600 /home/siteadm/.ssh/authorized_keys

# configure php-fpm
sed -i.ori 's/^listen =.*/listen = 127.0.0.1:9000/g' /etc/php-fpm.d/www.conf
sed -i 's/^user =.*/user = siteadm/g' /etc/php-fpm.d/www.conf
sed -i 's/^group =.*/group = netsite/g' /etc/php-fpm.d/www.conf
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
sudo touch /.user-data-app.phpfpm.complete

# configure AWS credential for CloudWatch
sudo mkdir -p /root/.aws/
cat >/root/.aws/credentials <<EOF
[default]
region = ap-southeast-1
aws_access_key_id = ${AWS_CLOUDWATCH_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_CLOUDWATCH_SECRET_ACCESS}
EOF
sudo chmod 600 /root/.aws/credentials

# generate ssl key and cert
sudo mkdir -p /etc/pki/nginx/private
sudo openssl req -subj "/CN=${TLS_COMMON_NAME}/O=${TLS_ORGANIZATION}/OU=${TLS_ORGANIZATIONAL_UNIT}/C=${TLS_COUNTRY}" \
    -new -newkey rsa:2048 -sha256 -keyout /etc/pki/nginx/private/server.key \
    -days 3650 -nodes -x509 -out /etc/pki/nginx/server.crt

# pull nginx configurations from S3
aws_exec=/usr/local/bin/aws
cd /etc/nginx/
sudo mv nginx.conf nginx.conf.ori
$aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/configs/nginx.conf .
sudo chown root:root nginx.conf
cd /etc/nginx/conf.d/
$aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/configs/gtp.conf .
rm -Rf default.conf
sudo chown root:root /etc/nginx/conf.d/gtp.conf
cd /usr/lib64/nginx/modules/
$aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/configs/ngx_nchan_module_nginx1.24.0_rhel9_04ba270ccd8098407.tar.gz .
tar -xzf ngx_nchan_module_nginx1.24.0_rhel9_04ba270ccd8098407.tar.gz
sudo mkdir -p /usr/share/nginx/modules/
cat >/usr/share/nginx/modules/mod-nchan.conf <<EOF
load_module "/usr/lib64/nginx/modules/ngx_nchan_module.so";
EOF

sudo systemctl start nginx
sudo systemctl enable nginx
sudo touch /.user-data-app.nginx.complete

# install cloudwatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
sudo dnf -y localinstall amazon-cloudwatch-agent.rpm
sudo mkdir -p /etc/cloudwatch
cd /etc/cloudwatch
$aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/configs/amazon-cloudwatch-agent.json .
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/etc/cloudwatch/amazon-cloudwatch-agent.json
sudo touch /.user-data-app.cloudwatch.complete

# nginx dir is /usr/local/nginx/html
sudo mkdir -p /usr/local/nginx/html
cd /usr/local/nginx/html/
$aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/gtp.zip .
$aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/gtp-db.tar.gz .
unzip gtp.zip
cd /usr/local/nginx/html/gtp/source/snapapp_otc

function config_bootstrap() {
    $aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/configs/config.ini .
    cd /root/
    $aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/configs/bootstrap.sh .
    sed -i "s/@@S3ACCESS@@/${AWS_CLOUDWATCH_ACCESS_KEY_ID}/g" /root/bootstrap.sh
    sed -i "s/@@S3SECRET@@/${AWS_CLOUDWATCH_SECRET_ACCESS}/g" /root/bootstrap.sh
    sed -i "s/@@S3BUCKET@@/${AWS_S3_BUCKET_NAME}/g" /root/bootstrap.sh
    sudo chmod 755 /root/bootstrap.sh
}

$aws_exec s3api head-object --bucket ${AWS_S3_BUCKET_NAME} --key configs/deployed_flag && DEPLOY_FLAG_EXISTS=true
$aws_exec s3api head-object --bucket ${AWS_S3_BUCKET_NAME} --key configs/config-bootstrapped.ini && CONFIG_EXISTS=true
CONFIG_SIZE=$(/usr/local/bin/aws s3api head-object --bucket ${AWS_S3_BUCKET_NAME} --key configs/config-bootstrapped.ini --output json --query 'ContentLength')

if [ $DEPLOY_FLAG_EXISTS ]; then
    if [ $CONFIG_EXISTS ]; then
        if [ $CONFIG_SIZE -eq 0 ]; then
            config_bootstrap
        else
            $aws_exec s3 cp s3://${AWS_S3_BUCKET_NAME}/configs/config-bootstrapped.ini .
            mv config-bootstrapped.ini config.ini
        fi
    else
        config_bootstrap
    fi
else
    config_bootstrap
fi

sudo touch /.user-data-app.git.complete
cd /usr/local/nginx/html/
sudo rm -Rf gtp.zip __MACOSX
mkdir /usr/local/nginx/html/gtp/source/snapapp_otc/logs
sudo touch /usr/local/nginx/html/gtp/source/snapapp_otc/logs/snap.log
chmod -Rf 777 /usr/local/nginx/html/gtp/source/snapapp_otc/logs
chown -Rf siteadm:netsite gtp
chmod -Rf 777 /var/lib/php/session
sudo touch /.user-data-app.staging.complete

# configure logrotate for snap logs
cat >/etc/logrotate.d/snapapp_otc <<EOF
/usr/local/nginx/html/gtp/source/snapapp_otc/logs/*.log {
        daily
        missingok
        rotate 14
        compress
        delaycompress
        notifempty
        create 666 siteadm netsite
        sharedscripts
        postrotate
        endscript
}
EOF

# install ssm agent
sudo dnf install -y https://s3.region.amazonaws.com/amazon-ssm-region/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl restart amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

# install codedeploy agent
sudo rm -f /root/.aws/credentials
sudo wget https://aws-codedeploy-ap-southeast-1.s3.ap-southeast-1.amazonaws.com/latest/install
sudo chmod 755 install
sudo ./install auto
sudo systemctl enable codedeploy-agent
sudo touch /.user-data-app.codedeploy.complete

# create a flag file indicating deployment is complete
sudo touch /.user-data-app.all.complete

## -- end --
