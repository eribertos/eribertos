#!/bin/bash
#
#===============================================================================
#
#          FILE:  FwBasic.sh
#
#         USAGE:  bash FwBasic.sh start ou bash FwBasic.sh stop
#
#   DESCRIPTION:  Controle de acesso
#
#         NOTES:  Liberando http e https, restringindo ssh, criando log de conexão com banco de dados
#        AUTHOR:  Eriberto eribertos@gmail.com
#       VERSION:  1.1
#       CREATED:  26/09/2024
#      REVISION:  3
#===============================================================================


function usage() {
    echo "Uso: $0 {start|stop}"
    echo "  start  - Adiciona regras do iptables"
    echo "  stop   - Limpa todas as regras do iptables"
    exit 1
}

if [[ "$EUID" -ne 0 ]]; then
   echo "Este script precisa ser executado como root."
   exit 1
fi

function stop_iptables() {
    echo "Limpando todas as regras do iptables..."
    iptables -F    # Limpa as regras da cadeia padrão
    iptables -X    # Remove todas as cadeias definidas pelo usuário
    iptables -Z    # Zera todos os contadores de pacotes e bytes
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT


    echo "Regras do iptables limpas."
}

function start_iptables() {
     echo "Adicionando regras ao iptables."

# Segurança de rede
echo "Aplicando configurações de segurança de rede..."
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.conf.all.log_martians=1
sysctl -w net.ipv4.conf.default.log_martians=1
sysctl -w net.ipv4.conf.all.rp_filter=1
sysctl -w net.ipv4.conf.default.rp_filter=1
sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1

# Proteção de execução
echo "Aplicando proteções de execução..."
sysctl -w kernel.exec-shield=1
sysctl -w kernel.randomize_va_space=2

# Desativar IP forwarding
echo "Desativando o encaminhamento de IP..."
sysctl -w net.ipv4.ip_forward=0

# Proteção contra sysrq
echo "Desativando sysrq para maior segurança..."
sysctl -w kernel.sysrq=0

# Proteção contra Core Dumps
echo "Desativando core dumps para processos suid..."
sysctl -w fs.suid_dumpable=0

# Recarregar as configurações de sysctl.conf
echo "Recarregando configurações do sysctl.conf..."
sysctl -p

echo "Configurações de segurança aplicadas com sucesso."

# Zera todas as regras anteriores
iptables -F
iptables -X
iptables -Z

# Define política padrão para INPUT, FORWARD e OUTPUT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Libera tráfego da interface de loopback
iptables -A INPUT -i lo -j ACCEPT

# Libera respostas de conexões já estabelecidas e pacotes relacionados
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Libera portas 80 (HTTP) e 443 (HTTPS) para toda a internet
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Libera porta 22 (SSH) IPs específicos
iptables -A INPUT -p tcp -s 192.168.125.125 --dport 22 -j ACCEPT

# Liberando algum IP acesso full
iptables -A INPUT -s 192.168.120.120 -j ACCEPT

# Liberando Mysql para rede seade
iptables -A INPUT -p tcp --dport 5432 -j LOG --log-prefix "PostgreSQL Connection: " --log-level 4
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
iptables -A INPUT -p tcp --dport 3306 -j LOG --log-prefix "MySQL Connection: " --log-level 4
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT

# Liberando PING da rede interna
iptables -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT

# Liberando zabbix.
iptables -A INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A INPUT -p tcp --dport 10051 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Log de pacotes bloqueados
iptables -A INPUT -j LOG --log-prefix "iptables bloqueado: "

# Bloqueia todo o tráfego que não foi permitido explicitamente
iptables -A INPUT -j DROP

 echo "Regras adicionadas."

}

 if [ $# -lt 1 ]; then
    usage
fi

case "$1" in
    start)
        start_iptables
        ;;
    stop)
        stop_iptables
        ;;
    *)
        usage
        ;;
esac

exit 0
