#!/bin/bash 
#########################################################################################
# VhostTemplate.sh
# Versao: 1.0.5
# Desc: Utiliza um template vhost para adionar um novo projeto
# Autor: Eribertos
# Email: eribertos@gmail.com
# Utilização: bash VhostTemplate.sh seudominio.com.br
# Date: 17/07/2023
#########################################################################################

ULTIMO=$(ls /etc/httpd/sites-available/ |grep 0 |tail -n1 |cut -d "0" -f2 |cut -d "-" -f1)

ID=$(($ULTIMO + 1))

if [ -d "/etc/apache2" ]; then
        echo "Distro debian Based"
        WEBSERVER="apache2"
else
        echo "Distro redhat based"
        WEBSERVER="httpd"
fi

echo $WEBSERVER






if [ $# -gt 0 ]

then
        cp /etc/$WEBSERVER/sites-available/Template.conf /etc/$WEBSERVER/sites-available/0$ID-$1.conf

        sed -i "s/template/$1/g" /etc/$WEBSERVER/sites-available/0$ID-$1.conf
        sed -i "s/apache2/$WEBSERVER/g" /etc/$WEBSERVER/sites-available/0$ID-$1.conf
        echo "Site $1 habilitado"

else
                echo "Digite o nome da URL/subdominio: Ex: bash VhostTemplate.sh meusite.site.com.br "

fi

if [ $WEBSERVER = apache2 ];then
        echo "Servidor Debian based"
        a2ensite /etc/$WEBSERVER/sites-available/0$ID-$1.conf > /dev/null
        service apache2 reload > /dev/null
else
        echo "servidor redhat based"
        ln -s /etc/httpd/sites-available/0$ID-$1.conf /etc/httpd/sites-enabled/0$ID-$1.conf
        service httpd reload > /dev/null

fi
