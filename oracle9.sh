#hostnamectl set-hostname CLD-SRV-WEB-03

#disable SElinux in current session
setenforce 0

#disable selinux after reboot
#old style (deprecated)
#sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/sysconfig/selinux
#sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
#new style with grub change
#sed -i.bak '/^GRUB_CMDLINE_LINUX="/ s/"$/ selinux=0&/' /etc/default/grub
#grub2-mkconfig -o /boot/grub2/grub.cfg
#using grubby
grubby --update-kernel ALL --args selinux=0

#enable file swap
sudo swapoff -a
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo swapon /swapfile

#install repos
dnf update -y
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf update -y
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
#install php
dnf module install -y php:remi-8.3
dnf install -y php-bcmath php-fpm php-mysqlnd php-curl php-ctype php-opcache php-fileinfo php-json php-mbstring php-openssl php-pdo php-tokenizer php-dom php-xml php-gd php-redis
#chown root:gitlab-runner /var/lib/php/opcache
#chown root:gitlab-runner /var/lib/php/session
#chown root:gitlab-runner /var/lib/php/wsdlcache

echo 'export EDITOR=nano' >>  ~/.bashrc
#ln -s /usr/share/httpd /home/apache
mkdir -p /home/apache
cp ~/.bashrc /home/apache/
cp ~/.cshrc /home/apache/
cp ~/.tcshrc /home/apache/
chown apache:apache -R /home/apache
usermod --shell /bin/bash apache
usermod -d /home/apache apache

#install nodejs
#curl --silent --location https://rpm.nodesource.com/setup_20.x | sudo bash -
#dnf -y install nodejs
# Download and install fnm:
curl -o- https://fnm.vercel.app/install | bash
# Download and install Node.js:
fnm install 22



#install databases
dnf install -y mariadb-server

#install additional utils
dnf install -y composer git nginx bzip2 fail2ban htop wget tar nano rsync
#add nginx configs
sed -i "s|include /etc/nginx/conf.d/\*\.conf;|include /etc/nginx/conf.d/\*\.conf; \n include /etc/nginx/sites-enabled/\*;|g" /etc/nginx/nginx.conf

#upload jails for fail2ban
curl -o /etc/fail2ban/jail.local https://raw.githubusercontent.com/Forsakenrox/utils/main/fail2ban/jail.local

#install phpmyadmin
DATA="$(wget https://www.phpmyadmin.net/home_page/version.txt -q -O-)"
URL="$(echo $DATA | cut -d ' ' -f 3)"
VER="$(echo $DATA | cut -d ' ' -f 1)"
curl -o phpMyAdmin-${VER}-all-languages.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${VER}/phpMyAdmin-${VER}-all-languages.tar.gz
tar xvf phpMyAdmin-${VER}-all-languages.tar.gz
rm -rf phpMyAdmin-*.tar.gz
sudo mv phpMyAdmin-*/ /var/www/phpmyadmin
cp /var/www/phpmyadmin/config.sample.inc.php  /var/www/phpmyadmin/config.inc.php
#randomBlowfishSecret=$(openssl rand -base64 32)
randomBlowfishSecret=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
sed -i "s|\$cfg\['blowfish_secret'\]".*"|\$cfg\['blowfish_secret'\] = '${randomBlowfishSecret}';|" /var/www/phpmyadmin/config.inc.php
#sed -i "s|\['AllowNoPassword'\] = false;|\['AllowNoPassword'\] = true;|" /var/www/phpmyadmin/config.inc.php
mkdir -p /etc/nginx/sites-available/
mkdir -p /etc/nginx/sites-enabled/
curl -o /etc/nginx/sites-available/phpmyadmin https://raw.githubusercontent.com/Forsakenrox/utils/main/phpmyadmin
ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/

#install gitlab-runner
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/rpm/gitlab-runner_amd64.rpm"
rpm -Uvh gitlab-runner_amd64.rpm
gitlab-runner uninstall
gitlab-runner install --user=apache --working-directory=/home/apache
service gitlab-runner restart
#chown -R gitlab-runner:gitlab-runner /var/www
chown -R apache:apache /var/www

#Highload optimisation
curl -o limits.conf https://raw.githubusercontent.com/Forsakenrox/utils/main/systemd/limits.local
mkdir -p /etc/systemd/system/php-fpm.service.d
mkdir -p /etc/systemd/system/nginx.service.d
mkdir -p /etc/systemd/system/mariadb.service.d
cp limits.conf /etc/systemd/system/php-fpm.service.d/limits.conf
cp limits.conf /etc/systemd/system/nginx.service.d/limits.conf
cp limits.conf /etc/systemd/system/mariadb.service.d/limits.conf
systemctl daemon-reload

#php.ini configuring
sed -i 's/.*memory_limit = .*/memory_limit = 1024M/' /etc/php.ini
sed -i 's/.*max_execution_time = .*/max_execution_time = 300/' /etc/php.ini
sed -i 's/.*upload_max_filesize = .*/upload_max_filesize = 1024M/' /etc/php.ini
sed -i 's/.*post_max_size = .*/post_max_size = 1024M/' /etc/php.ini
sed -i 's/.*expose_php = .*/expose_php = Off/' /etc/php.ini

systemctl enable nginx
systemctl enable mariadb
systemctl enable php-fpm
systemctl enable fail2ban
systemctl enable gitlab-runner

#sed -i "s/user =".*"/user = gitlab-runner/g" /etc/php-fpm.d/www.conf
#sed -i "s/group =".*"/user = gitlab-runner/g" /etc/php-fpm.d/www.conf

#http
firewall-cmd --permanent --add-port=80/tcp
#https
firewall-cmd --permanent --add-port=443/tcp
#phpmyadmin
firewall-cmd --permanent --add-port=10000/tcp
#mysql
firewall-cmd --permanent --add-port=3306/tcp
#mongodb
firewall-cmd --permanent --add-port=27017/tcp
#redis
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --reload

service nginx restart
service mariadb restart
service php-fpm restart
service fail2ban restart
service gitlab-runner restart

mysql_secure_installation
