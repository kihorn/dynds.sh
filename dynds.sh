#!/bin/bash
configPath=/etc/dynds.conf

function generateConfig() {

    clear

    # Check if the user has read and write authorisation for the configuration file
    if ! [ -r "/etc" ] || ! [ -w "/etc" ]; then
        echo "Error: User does not have sufficient rights to read the existing configuration file or create a new one."
        exit 1
    fi

    echo "Welcome to DynDS client installer!"
    echo ""
    echo "which service do you want to use?"
    echo "1: Cloudflare"
    echo "2: Strato"
    echo ""

    read SERVICE

    echo ""
    echo "which stack do you want to update?"
    echo "1: IPv4 only"
    echo "2: IPv6 only"
    echo "3: Dual stack"
    echo ""

    read STACK

    echo ""
    echo "which DNS server do you want to dig on?"
    echo "1: Cloudflare"
    echo "2: Google"
    echo "3: Strato"
    echo "4: Telekom Germany"
    echo ""

    read DNS

    echo ""
    echo "please enter the subdomain to be updated"
    echo "   use . for delimiting deeper levels"

    read SUBDOMAIN

    echo ""
    echo "please enter your domain"

    read DOMAIN

    if [ "$SERVICE" == "2" ]; then
        echo ""
        echo "please enter your dynamic DNS password"

        read -s PASSWORD

        echo "please enter your dynamic DNS password again"

        read -s PASSWORD_CHECK

    elif [ "$SERVICE" == "1" ]; then
        echo ""
        echo "please enter your Cloudflare-Email"
        read CF_API_EMAIL

        echo ""
        echo "please enter your Cloudflare-API-Key"
        read CF_API_KEY
    fi

    echo ""
    read -e -p "Would you like to use a cronjob? [Y/n]" cronStatus

    if [ "$cronStatus" == "Y" ]; then
        echo ""
        read -e -p "cronjob [Default: Every 5 Minutes]: " -i "*/5 * * * *" CRON
    fi

    echo ""
    echo "configuration finished, will update your service with selected stack option:$STACK"
    echo "subdomain to be updated:$SUBDOMAIN using account:$DOMAIN"
    echo ""
    echo "saving to config file now"

    # Create Config File
    touch $configPath

    echo "#DynDS config created on $(date)" >>$configFile
    echo "" >>$configFile
    echo "# set the update variables" >>$configFile
    echo "CURRENT_IPV4=$(curl -4 -s ifconfig.io)" >>$configFile
    echo "CURRENT_IPV6=$(curl -6 -s ifconfig.io)" >>$configFile
    echo "DISCOVERED_IPV4=" >>$configFile
    echo "DISCOVERED_IPV6=" >>$configFile
    echo "updateIPv4=false" >>$configFile
    echo "updateIPv6=false" >>$configFile
    echo "" >>$configFile

    if [ $SERVICE == "1" ]; then
        echo "#service to used e.g. Strato, Cloudflare etc." >>$configFile
        echo "SERVICE=\"Cloudflare\"" >>$configFile
    elif [ $SERVICE == "2" ]; then
        echo "#service to used e.g. Strato, Cloudflare etc." >>$configFile
        echo "SERVICE=\"Strato\"" >>$configFile
    else
        echo "service selection not valid, please start over!"
    fi

    if [ "$STACK" == "1" ]; then
        echo "#stack to be updated" >>$configFile
        echo "STACK=\"v4\"" >>$configFile
    elif [ "$STACK" == "2" ]; then
        echo "#stack to be updated" >>$configFile
        echo "STACK=\"v6\"" >>$configFile
    elif [ "$STACK" == "3" ]; then
        echo "#stack to be updated" >>$configFile
        echo "STACK=\"DS\"" >>$configFile
    else
        echo "stack selection not valid, please start over!"
    fi

    if [ "$DNS" == "1" ]; then
        echo "#DNS to dig on" >>$configFile
        echo "DNS=\"1.1.1.1\"" >>$configFile
    elif [ "$DNS" == "2" ]; then
        echo "#DNS to dig on" >>$configFile
        echo "DNS=\"8.8.8.8\"" >>$configFile
    elif [ "$DNS" == "3" ]; then
        echo "#DNS to dig on" >>$configFile
        echo "DNS=\"212.227.123.16\"" >>$configFile
    elif [ "$DNS" == "4" ]; then
        echo "#DNS to dig on" >>$configFile
        echo "DNS=\"217.5.100.185\"" >>$configFile
    else
        echo "DNS server not valid, please start over!"
    fi

    if [ "$SUBDOMAIN" != "" ]; then
        echo "#subdomain to be updated" >>$configFile
        echo "SUBDOMAIN=\"$SUBDOMAIN\"" >>$configFile
    else
        echo "subdomain can not be empty, please start over!"
    fi

    if [ "$DOMAIN" != "" ]; then
        echo "#domain or username for update" >>$configFile
        echo "DOMAIN=\"$DOMAIN\"" >>$configFile
    else
        echo "username can not be empty, please start over!"
    fi

    if [ $SERVICE == "1" ]; then
        echo "#cloudflare API Email"
        echo "CF_API_EMAIL=\"$CF_API_EMAIL\"" >>$configFile
        echo "#cloudflare API Key"
        echo "CF_API_KEY=\"$CF_API_KEY\"" >>$configFile
    elif [ $SERVICE == "2" ]; then
        if [ "$PASSWORD" == "$PASSWORD_CHECK" ]; then
            echo "#password for update" >>$configFile
            echo "PASSWORD=\"$PASSWORD\"" >>$configFile
        else
            echo "passwords do not match, please start over!"
        fi
    fi

    if [ "$CRON" != "" ]; then
        echo "#cronjob" >>$configFile
        echo "CRON=\"$CRON\"" >>$configFile
    fi

    clear
    echo ""
    echo "configuration file saved, you can run the script now!"
    echo ""
}

function checkIP() {
    # Check IPv4
    if [ $STACK == "v4" ] || [ $STACK == "DS" ]; then

        CURRENT_IPV4="$(curl -4 -s ifconfig.io)"
        echo "debug: current IPV4 address: $CURRENT_IPV4"

        DISCOVERED_IPV4="$(dig +short $SUBDOMAIN.$DOMAIN A @$DNS)"
        echo "debug: discovered IPV4 address: $DISCOVERED_IPV4"

        if [ "$DISCOVERED_IPV4" != "$CURRENT_IPV4" ]; then
            updateIPv4=true
            echo "debug: update v4"
        else
            updateIPv4=false
            echo "debug: no update v4"
        fi
    fi

    # Check IPv6
    if [ $STACK == "v6" ] || [ $STACK == "DS" ]; then

        CURRENT_IPV6="$(curl -6 -s ifconfig.io)"
        echo "debug: current IPV6 address: $CURRENT_IPV6"

        DISCOVERED_IPV6="$(dig +short $SUBDOMAIN.$DOMAIN AAAA @$DNS)"
        echo "debug: discovered IPV6 address: $DISCOVERED_IPV6"

        if [ "$DISCOVERED_IPV6" != "$CURRENT_IPV6" ]; then
            updateIPv6=true
            echo "debug: update v6"
        else
            updateIPv6=false
            echo "debug: no update v6"
        fi
    fi
}

function dyndnsCF() {

    if [ "$updateIPv4" == true ] || [ "$updateIPv6" == true ]; then
        # Get Zone ID
        cloudflareZoneID=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN&status=active" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "X-Auth-Email: $CF_API_EMAIL" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )

        # Get Record ID
        cloudflareRecordIdIPv4=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$cloudflareZoneID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )
    fi
    # Update IPv4
    if [[ ($STACK == "v4" || $STACK == "DS") && $updateIPv4 == true ]]; then
        # Get Record ID
        cloudflareRecordIdIPv4=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$cloudflareZoneID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )

        # Update DNS
        resultV4=$(
            curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$cloudflareZoneID/dns_records/$cloudflareRecordIdIPv4" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"A\",\"name\":\"$SUBDOMAIN\",\"content\":\"$CURRENT_IPV4\",\"ttl\":1,\"proxied\":false}"
        )
    fi
    echo "$resultV4"
    # Update IPv6
    if [[ ($STACK == "v6" || $STACK == "DS") && $updateIPv6 == true ]]; then
        # Get Record ID
        cloudflareRecordIdIPv6=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$cloudflareZoneID/dns_records?type=AAAA&name=$SUBDOMAIN.$DOMAIN" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )

        # Update DNS
        resultV6=$(
            curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$cloudflareZoneID/dns_records/$cloudflareRecordIdIPv6" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"AAAA\",\"name\":\"$SUBDOMAIN\",\"content\":\"$CURRENT_IPV6\",\"ttl\":1,\"proxied\":false}"
        )
    fi
    echo "$resultV6"
    # Check Update
    if [ "$resultV4" == *"\"success\":false"* ]; then
        echo "$resultV4"
        echo "debug: there was an error updating your dynamic DNS"
    fi

    if [ "$resultV6" == *"\"success\":false"* ]; then
        echo "$resultV6"
        echo "debug: there was an error updating your dynamic DNS"
    fi

}

function dyndnsStrato() {

    # Update DNS
    if [ $STACK == "v4" ] && [ $updateIPv4 == true ]; then
        RESULT="$(curl --silent --show-error "https://$DOMAIN:$PASSWORD@dyndns.strato.com/nic/update?hostname=$SUBDOMAIN.$DOMAIN&myip=$CURRENT_IPV4")"
        echo "debug: v4 update result: "$RESULT

    elif [ $STACK == "v6" ] && [ $updateIPv6 == true ]; then
        RESULT="$(curl --silent --show-error "https://$DOMAIN:$PASSWORD@dyndns.strato.com/nic/update?hostname=$SUBDOMAIN.$DOMAIN&myip=$CURRENT_IPV6")"
        echo "debug: v6 update result: "$RESULT

    elif [ $STACK == "DS" ] && ([ $updateIPv4 == true ] || [ $updateIPv6 == true ]); then
        RESULT="$(curl --silent --show-error "https://$DOMAIN:$PASSWORD@dyndns.strato.com/nic/update?hostname=$SUBDOMAIN.$DOMAIN&myip=$CURRENT_IPV4,$CURRENT_IPV6")"
        echo "debug: dual stack update result: "$RESULT
    else
        echo "debug: there was an error updating your dynamic DNS"
    fi
}

function checkCron() {
    # Complete file path
    FILE=$(readlink --canonicalize --no-newline $BASH_SOURCE)
    # Check whether the cronjob already exists
    crontab -l | grep -q $FILE && cronStatus=true && echo 'debug: a cronjob exist' || cronStatus=false

    # Check if the cronjob has changed
    cronjob=$(crontab -l | grep -i $FILE)
    if [ "$cronjob" == "${CRON} ${FILE}" ]; then
        echo "debug: cron is up to date"
        cronUpdate=false
    elif [ "$cronStatus" ] && [ "$CRON" == "" ]; then
        crontab -l >cronjob
        echo "debug: remove cronjob"
        sed_file=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<<"$FILE")
        sed -i "\%$sed_file%d" "cronjob"
        crontab cronjob
        rm cronjob
    else
        echo "debug: cron in the config has changed"
        cronUpdate=true
    fi

    # Create or update cronjob
    if [ "$cronStatus" == false ] && [ "$CRON" != "" ]; then
        echo "debug: install cronjob"
        crontab -l >cronjob
        echo "${CRON}" "${FILE}" >>cronjob
        crontab cronjob
        rm cronjob
    elif [ "$cronStatus" == true ] && [ "$cronUpdate" == true ] && [ "$CRON" != "" ]; then
        echo "debug: update cronjob"
        crontab -l | grep -v $FILE | crontab -
        crontab -l >cronjob
        echo "${CRON}" "${FILE}" >>cronjob
        crontab cronjob
        rm cronjob
    fi
}

function changeCron() {
    echo ""
    read -e -p "cronjob [Default: Every 5 Minutes]: " -i "*/5 * * * *" CRON
    if grep -q "CRON=" "$configFile"; then
        sed -i "s#^CRON=.*#CRON=\"${CRON}\"#" "$configFile"
        echo "Cron replaced."
    else
        echo "#cronjob" >>$configFile
        echo "CRON=\"$CRON\"" >>$configFile
        echo "Cron added."
    fi
}

# Loop through all the command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --cron)
        cronFlag=true
        ;;
    --configfile)
        configPath="$2"
        shift
        ;;
    *)
        # Handle unknown options
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift # Move to the next argument
done

source $configPath
configFile=$configPath

if [ -f "$configFile" ]; then

    if [ "$cronFlag" == true ]; then
        changeCron
    fi

    echo "debug: $configFile exists"
    checkCron
    checkIP

    case $SERVICE in
    Cloudflare)
        dyndnsCF
        ;;
    Strato)
        dyndnsStrato
        ;;
    esac
else
    generateConfig
fi
