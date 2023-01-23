mkdir -p /root/sqldumps/
ssh root@10.0.0.1 "mkdir -p /root/sqldumps/"
for databaseName in aptekirls doctor gefest linguapharm rlsnet sppvr support ;
  do
    echo "dumping" $databaseName
	ssh root@10.0.0.1 "rm -rf /root/sqldumps/$databaseName.sql.bz2"
    mysqldump -uroot -pPASS --add-drop-database --databases $databaseName | bzip2 -c | ssh -l root 10.0.0.1 "cat > /root/sqldumps/$databaseName.sql.bz2"
  done
for databaseName in aptekirls doctor gefest linguapharm rlsnet sppvr support ;
  do
    echo "refreshing" $databaseName
    ssh root@10.0.0.1 "bzip2 -dc < /root/sqldumps/$databaseName.sql.bz2 | ionice -c2 -n7 mysql -uroot -pPASS"
  done
rsync -avh --progress --exclude 'phpmyadmin' --exclude 'site.ru' /var/www/ root@10.0.0.1:/var/www/
ssh root@10.0.0.1 "chown -R apache:apache /var/www/"
rsync -Lavh --progress --exclude 'site.ru' /etc/letsencrypt/live/ root@10.0.0.1:/etc/nginx/ssl/
ssh root@10.0.0.1 "service nginx restart"
