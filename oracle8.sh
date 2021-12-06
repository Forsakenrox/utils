#hostnamectl set-hostname CLD-SRV-WEB-03
#disable SElinux in current session
setenforce 0
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/sysconfig/selinux

#install repos
yum update
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf update
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
#install php
dnf module install -y php:remi-8.1
dnf install -y php-bcmath php-fpm php-mysqlnd php-curl php-ctype php-opcache php-fileinfo php-json php-mbstring php-openssl php-pdo php-tokenizer php-dom php-xml
#install databases
dnf install -y mariadb-server mariadb-client
#install php
DATA="$(wget https://www.phpmyadmin.net/home_page/version.txt -q -O-)"
URL="$(echo $DATA | cut -d ' ' -f 3)"
VER="$(echo $DATA | cut -d ' ' -f 1)"
curl -o phpMyAdmin-${VER}-all-languages.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${VER}/phpMyAdmin-${VER}-all-languages.tar.gz
tar xvf phpMyAdmin-${VER}-all-languages.tar.gz
rm -rf phpMyAdmin-*.tar.gz
sudo mv phpMyAdmin-*/ /var/www/phpmyadmin
cp /var/www/phpmyadmin/config.sample.inc.php  /var/www/phpmyadmin/config.inc.php
randomBlowfishSecret=$(openssl rand -base64 32)
sed -i "s|cfg\['blowfish_secret'\]".*"|cfg['blowfish_secret'] = '${randomBlowfishSecret}';|" /var/www/phpmyadmin/config.inc.php
mkdir -p /etc/nginx/sites-available/
mkdir -p /etc/nginx/sites-enabled/
curl -o /etc/nginx/sites-available/phpmyadmin https://raw.githubusercontent.com/Forsakenrox/utils/main/phpmyadmin
ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/

#install additional utils
dnf install -y composer git nginx bzip2 fail2ban htop
#install gitlab-runner
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/rpm/gitlab-runner_amd64.rpm"
rpm -Uvh gitlab-runner_amd64.rpm
chown -R gitlab-runner:gitlab-runner /var/www

systemctl enable nginx
systemctl enable mariadb
systemctl enable php-fpm
systemctl enable fail2ban
systemctl enable gitlab-runner

sed -i "s/user =".*"/user = gitlab-runner/g" /etc/php-fpm.d/www.conf
sed -i "s/group =".*"/user = gitlab-runner/g" /etc/php-fpm.d/www.conf


firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=10000/tcp
firewall-cmd --reload

service nginx start
service mariadb start
service php-fpm start
service fail2ban start
service gitlab-runner start