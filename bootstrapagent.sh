#!/bin/bash
yum -y install http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
yum -y install zabbix-agent
systemctl start zabbix-agent
systemctl enable zabbix-agent
#sed -i 's/# DebugLevel=3/DebugLevel=3/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Server=127.0.0.1/Server=192.168.56.2/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# ListenPort=10050/ListenPort=10050/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# ListenIP=0.0.0.0/ListenIP=0.0.0.0/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# StartAgents=3/StartAgents=3/' /etc/zabbix/zabbix_agentd.conf
##sed -i '/StartAgents=3/a ServerPort=10051' /etc/zabbix/zabbix_agentd.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=192.168.56.2/' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# HostnameItem=system.hostname/HostnameItem=system.hostname/' /etc/zabbix/zabbix_agentd.conf
sed -i "s/# UserParameter=/UserParameter=mysql.questions,mysqladmin -uroot status | awk \'FNR == 1 {print \$6}\'/" /etc/zabbix/zabbix_agentd.conf

sed -i '/ListenIP=/a ListenIP=192.168.56.3' /etc/zabbix/zabbix_agentd.conf
sed -i '/ListenPort=/a ListenPort=10050' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/Hostname=Zabbix agent/' /etc/zabbix/zabbix_agentd.conf


yum -y install zabbix-sender
systemctl restart zabbix-agent


