#prepating soft
apt install curl wget tar git zip nano htop openssl nginx mariadb-server -y

#php repo
sudo wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

#node repo
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

#composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

#additional setup
#apt install nodejs -y
apt install nodejs php8.2-{bcmath,curl,mbstring,mysql,tokenizer,xml,zip,fpm,opcache} -y

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

#Настриваем права и юзеров
chown -R www-data:www-data /var/www
mkdir /home/www-data
chown -R www-data:www-data /home/www-data
usermod -d /home/www-data www-data
usermod -s /bin/bash www-data

systemctl enable nginx
systemctl enable mariadb
systemctl enable php8.2-fpm

service nginx restart
service mariadb restart
service php8.2-fpm restart

mysql_secure_installation
passwd www-data
