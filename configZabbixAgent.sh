#!/bin/bash
SERVER=`hostname`
ZABBIX=`getent hosts zabbix |cut -d " " -f1`

        grep -wv "#" /etc/zabbix_agentd.conf | grep -v "^$" > /tmp/zabbix.conf
        sed -i "s/Zabbix server/$SERVER/g" /tmp/zabbix.conf
        sed -i "s/127.0.0.1/$ZABBIX/g" /tmp/zabbix.conf
        cat /tmp/zabbix.conf > /etc/zabbix_agentd.conf
        systemctl restart zabbix-agent
        firewall-cmd --new-zone=zabbix --permanent
        firewall-cmd --permanent --zone=zabbix --add-port=10050/tcp
        firewall-cmd --reload
        rm -f /tmp/zabbix.conf
