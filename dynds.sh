#!/bin/bash

CURRENT_IPV4="$(curl -4 -s ifconfig.io)"
CURRENT_IPV6="$(curl -6 -s ifconfig.io)"
#echo $CURRENT_IPV4
#echo $CURRENT_IPV6
DOMAIN=""
STRATO_PW=""
SUBDOMAIN=""
DNS="1.1.1.1"
IPV4="$(dig +short $SUBDOMAIN.$DOMAIN A @$DNS)"
IPV6="$(dig +short $SUBDOMAIN.$DOMAIN AAAA @$DNS)"
echo $IPV4
echo $IPV6

if [ "$IPV4" != "$CURRENT_IPV4" ] || [ "$IPV6" != "$CURRENT_IPV6" ]
then
	echo "Update"
else
	echo "No Update"
fi

#RESULT="$(curl --silent --show-error "https://$DOMAIN:$STRATO_PW@dyndns.strato.com/nic/update?hostname=$SUBDOMAIN.$DOMAIN&myip=$CURRENT_IPV4,$CURRENT_IPV6")"
#echo $RESULT
