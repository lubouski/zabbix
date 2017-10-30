#!/bin/bash

yum -y install mariadb mariadb-server
/usr/bin/mysql_install_db --user=mysql
systemctl start mariadb
systemctl enable mariadb

#mysql -uroot
mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';" 
#mysql -uroot -e "quit;"

yum -y install http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
yum -y install zabbix-server-mysql zabbix-web-mysql

#zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql -uzabbix -pzabbix 
echo "zabbix" > /root/mysql
zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql -u zabbix -p zabbix --password="$(cat /root/mysql)"

sed -i '/DBHost=localhost/a DBHost=localhost' /etc/zabbix/zabbix_server.conf
##sed -i '/DBName=zabbix/a DBName=zabbix' /etc/zabbix/zabbix_server.conf
##sed -i '/DBUser=zabbix/a DBUser=zabbix' /etc/zabbix/zabbix_server.conf
sed -i '/DBPassword=/a DBPassword=zabbix' /etc/zabbix/zabbix_server.conf

systemctl start zabbix-server
systemctl enable zabbix-server
#yum install http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
#yum install zabbix-web-mysql

#vi /etc/httpd/conf.d/zabbix.conf  Riga to Minsk
sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone Europe\/Minsk/' /etc/httpd/conf.d/zabbix.conf
systemctl start httpd
systemctl enable httpd 

yum -y install zabbix-agent
systemctl start zabbix-agent
systemctl enable zabbix-agent

sed -i '/ListenPort=/a ListenPort=10051' /etc/zabbix/zabbix_server.conf
sed -i '/StartTrappers=/a StartTrappers=1' /etc/zabbix/zabbix_server.conf
#sed -i 's/# DebugLevel=3/DebugLevel=3/' /etc/zabbix/zabbix_agentd.conf

sed -i 's/Server=127.0.0.1/Server=192.168.56.2/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# ListenPort=10050/ListenPort=10051/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# ListenIP=0.0.0.0/ListenIP=0.0.0.0/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# StartAgents=3/StartAgents=3/' /etc/zabbix/zabbix_agentd.conf
##sed -i '/StartAgents=3/a ServerPort=10051' /etc/zabbix/zabbix_agentd.conf

sed -i 's/ServerActive=127.0.0.1/ServerActive=192.168.56.2/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# HostnameItem=system.hostname/HostnameItem=system.hostname/' /etc/zabbix/zabbix_agentd.conf
sed -i "s/# UserParameter=/UserParameter=mysql.questions,mysqladmin -uroot status | awk \'FNR == 1 {print \$6}\'/" /etc/zabbix/zabbix_agentd.conf

cp /vagrant/zabbix.conf.php /etc/zabbix/web/
yum -y install zabbix-get
systemctl restart zabbix-agent

# parse token

output=$(curl -i -X POST -H "Content-Type: application/json-rpc" -d '{"jsonrpc": "2.0", "method": "user.login", "params": {"user": "Admin", "password": "zabbix"}, "id": 1, "auth": null}' HTTP://192.168.56.2/zabbix/api_jsonrpc.php)

TOKEN="$(echo $output | awk 'FNR == 1 {print$30}' | cut -c 27-60)"



# template.create

value=$(curl -i -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "template.create", "params": {"host": "Test template", "groups": {"groupid": 1}}, "auth": '$TOKEN', "id": 1}' 192.168.56.2/zabbix/api_jsonrpc.php)

value2="$(echo $value | awk 'FNR == 1 {print$30}' | cut -d '"' -f 10)"

# Create group CloudHosts

host=$(curl -i -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "hostgroup.get", "params": {"filter": {"name": "CloudHosts"}}, "auth": '$TOKEN', "id": 1}' 192.168.56.2/zabbix/api_jsonrpc.php)

host2="$(echo $host | awk 'FNR == 1 {print$30}' | cut -c 27-28)"

host3=$([ $host2 != "[]" ] && echo "Existed" || curl -i -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "hostgroup.create", "params": {"name": "CloudHosts"}, "auth": '$TOKEN', "id": 1}' 192.168.56.2/zabbix/api_jsonrpc.php)

# parse gid

host4="$(echo $host3 | awk 'FNR == 1 {print$30}' | cut -d '"' -f 10)"



# AUTO REGISTRATION

curl -i -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "action.create", "params": {"name": "Autoreg", "eventsource": 2, "status": 0, "operations": [{"operationtype": 2}, {"operationtype": 4, "opgroup": [{"groupid": "'"$host4"'"}]}, {"operationtype": 6, "optemplate": [{"templateid": "'"$value2"'"}]} ]}, "auth": '$TOKEN', "id": 1}' 192.168.56.2/zabbix/api_jsonrpc.php



