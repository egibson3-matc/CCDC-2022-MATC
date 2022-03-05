#!/bin/bash

IPT="/sbin/iptables"
cmdClear="/usr/bin/clear"

# DNS servers you use: cat /etc/resolv.conf
DNS_SERVER=$(grep nameserver /etc/resolv.conf | cut -d " " -f2 | tr "\n" ' ')

#Emergency option
#DNS_SERVER="8.8.8.8 8.8.4.4"

cat << _EOF_

    Select a service to configure firewall rules for:
    
    1) Web Application Server
    2) DNS Server 
    3) Mail Server
    4) Splunk Server
    5) SSH Server
    6) SSH Client
    7) NTP Server
    0) Quit

_EOF_

read -p "Select a service [0-6] to configure firewall rules for: " PROMPT

#Deleting existing iptables rules
$IPT -F
$IPT -X

#Set chain default policy to DROP
$IPT -P INPUT   DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT  DROP

# ACCEPT DNS lookups
for ip in $DNS_SERVER
do
	echo "Allowing DNS lookups (tcp, udp port 53) to server '$ip'"
	$IPT -A OUTPUT -p udp -d $ip --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT  -p udp -s $ip --sport 53 -m state --state ESTABLISHED     -j ACCEPT
	$IPT -A OUTPUT -p tcp -d $ip --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT  -p tcp -s $ip --sport 53 -m state --state ESTABLISHED     -j ACCEPT
done

#######################################################################################################
## Required Rules

#Allow loopback connections
$IPT -A INPUT  -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

#Allowing NEW and ESTABLISHED connections using ports 80,443
$IPT -A OUTPUT -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A INPUT  -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED     -j ACCEPT

#Allowing ICMP outbound for ping
$IPT -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT  -p icmp -m state --state ESTABLISHED,RELATED     -j ACCEPT

#Allow outgoing connections to port 123 (ntp)
$IPT -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A INPUT  -p udp --sport 123 -m state --state ESTABLISHED     -j ACCEPT

#Splunk Forwarder Rules
$IPT -A OUTPUT -p tcp --dport 9997 -j ACCEPT
$IPT -A OUTPUT -p tcp --dport 8089 -j ACCEPT

#######################################################################################################
#Specific Firewall Rules

for SERVICE in $PROMPT
do

#Web: Allowing all inbound connections to ports 80,443
if [ $SERVICE == 1 ] 
then
    $IPT -I OUTPUT -p tcp --sport 80  -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 80  -j ACCEPT
    $IPT -I OUTPUT -p tcp --sport 443 -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 443 -j ACCEPT
    echo "Web server firewall rules configured."

#DNS: Allowing all outbound connections to port 53
elif [ $SERVICE == 2 ] 
then
    $IPT -I OUTPUT -p udp --sport 53 -j ACCEPT
    $IPT -I INPUT  -p udp --dport 53 -j ACCEPT
    $IPT -I OUTPUT -p tcp --sport 53 -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 53 -j ACCEPT
    echo "DNS server firewall rules configured."

#Mail: Allowing all outbound connections to ports 25,110,143
elif [ $SERVICE == 3 ] 
then
    #SMTP
    #Unencrypted
    $IPT -I OUTPUT -p tcp --sport 25  -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 25  -j ACCEPT
    #Encrypted SSL/TLS
    $IPT -I OUTPUT -p tcp --sport 465 -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 465 -j ACCEPT
    
    #POP3
    #Unencrypted
    $IPT -I OUTPUT -p tcp --sport 110 -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 110 -j ACCEPT
    #Encrypted SSL/TLS
    $IPT -I OUTPUT -p tcp --sport 995 -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 995 -j ACCEPT

    #IMAP
    #Unencrypted
    $IPT -I OUTPUT -p tcp --sport 143 -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 143 -j ACCEPT
    #Encrypted SSL/TLS
    $IPT -I OUTPUT -p tcp --sport 993 -j ACCEPT
    $IPT -I INPUT  -p tcp --dport 993 -j ACCEPT
    echo "Mail server firewall rules configured."

#Splunk: Allowing all Splunk service connections on ports 8000,9997,8089
elif [ $SERVICE == 4 ] 
then
    $IPT -I OUTPUT -p tcp -m multiport --sports 8000,9997,8089 -m state --state ESTABLISHED     -j ACCEPT
    $IPT -I INPUT  -p tcp -m multiport --dports 8000,9997,8089 -m state --state NEW,ESTABLISHED -j ACCEPT
    echo "Splunk server firewall rules configured."

#SSH Server: Allow all incomming connections to port 22
elif [ $SERVICE == 5 ] 
then
    $IPT -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED     -j ACCEPT
    $IPT -A INPUT  -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
    echo "SSH server firewall rules configured."

#SSH Client: Allow all connections on port 22
elif [ $SERVICE == 6 ] 
then
    $IPT -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
    $IPT -A INPUT  -p tcp --sport 22 -m state --state ESTABLISHED     -j ACCEPT
    echo "SSH client firewall rules configured."

#NTP Server: Allow incomming connections on port 123 (ntp)
elif [ $SERVICE == 7 ]
then
    $IPT -A OUTPUT -p udp --sport 123 -m state --state ESTABLISHED     -j ACCEPT
    $IPT -A INPUT  -p udp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
    echo "NTP server firewall rules configured."

elif [ $SERVICE == 0 ]
then
    break
fi

done
