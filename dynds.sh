#!/bin/bash
CONFIG_PATH=/etc/dynds.conf

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
    read -e -p "Would you like to use a cronjob? [Y/n]" CRONSTATUS

    if [ "$CRONSTATUS" == "Y" ]; then
        echo ""
        read -e -p "Cronjob [Default: Every 5 Minutes]: " -i "*/5 * * * *" CRON
    fi

    echo ""
    echo "configuration finished, will update your service with selected stack option:$STACK"
    echo "subdomain to be updated:$SUBDOMAIN using account:$DOMAIN"
    echo ""
    echo "saving to config file now"

    # Create Config File
    touch $CONFIG_PATH

    echo "#DynDS config created on $(date)" >>$CONFIG_FILE
    echo "" >>$CONFIG_FILE
    echo "# set the update variables" >>$CONFIG_FILE
    echo "CURRENT_IPV4=$(curl -4 -s ifconfig.io)" >>$CONFIG_FILE
    echo "CURRENT_IPV6=$(curl -6 -s ifconfig.io)" >>$CONFIG_FILE
    echo "DISCOVERED_IPV4=" >>$CONFIG_FILE
    echo "DISCOVERED_IPV6=" >>$CONFIG_FILE
    echo "Update_IPV4=false" >>$CONFIG_FILE
    echo "Update_IPV6=false" >>$CONFIG_FILE
    echo "" >>$CONFIG_FILE

    if [ $SERVICE == "1" ]; then
        echo "#service to used e.g. Strato, Cloudflare etc." >>$CONFIG_FILE
        echo "SERVICE=\"Cloudflare\"" >>$CONFIG_FILE
    elif [ $SERVICE == "2" ]; then
        echo "#service to used e.g. Strato, Cloudflare etc." >>$CONFIG_FILE
        echo "SERVICE=\"Strato\"" >>$CONFIG_FILE
    else
        echo "service selection not valid, please start over!"
    fi

    if [ "$STACK" == "1" ]; then
        echo "#stack to be updated" >>$CONFIG_FILE
        echo "STACK=\"v4\"" >>$CONFIG_FILE
    elif [ "$STACK" == "2" ]; then
        echo "#stack to be updated" >>$CONFIG_FILE
        echo "STACK=\"v6\"" >>$CONFIG_FILE
    elif [ "$STACK" == "3" ]; then
        echo "#stack to be updated" >>$CONFIG_FILE
        echo "STACK=\"DS\"" >>$CONFIG_FILE
    else
        echo "stack selection not valid, please start over!"
    fi

    if [ "$DNS" == "1" ]; then
        echo "#DNS to dig on" >>$CONFIG_FILE
        echo "DNS=\"1.1.1.1\"" >>$CONFIG_FILE
    elif [ "$DNS" == "2" ]; then
        echo "#DNS to dig on" >>$CONFIG_FILE
        echo "DNS=\"8.8.8.8\"" >>$CONFIG_FILE
    elif [ "$DNS" == "3" ]; then
        echo "#DNS to dig on" >>$CONFIG_FILE
        echo "DNS=\"212.227.123.16\"" >>$CONFIG_FILE
    elif [ "$DNS" == "4" ]; then
        echo "#DNS to dig on" >>$CONFIG_FILE
        echo "DNS=\"217.5.100.185\"" >>$CONFIG_FILE
    else
        echo "DNS server not valid, please start over!"
    fi

    if [ "$SUBDOMAIN" != "" ]; then
        echo "#subdomain to be updated" >>$CONFIG_FILE
        echo "SUBDOMAIN=\"$SUBDOMAIN\"" >>$CONFIG_FILE
    else
        echo "subdomain can not be empty, please start over!"
    fi

    if [ "$DOMAIN" != "" ]; then
        echo "#domain or username for update" >>$CONFIG_FILE
        echo "DOMAIN=\"$DOMAIN\"" >>$CONFIG_FILE
    else
        echo "username can not be empty, please start over!"
    fi

    if [ $SERVICE == "1" ]; then
        echo "#cloudflare API Email"
        echo "CF_API_EMAIL=\"$CF_API_EMAIL\"" >>$CONFIG_FILE
        echo "#cloudflare API Key"
        echo "CF_API_KEY=\"$CF_API_KEY\"" >>$CONFIG_FILE
    elif [ $SERVICE == "2" ]; then
        if [ "$PASSWORD" == "$PASSWORD_CHECK" ]; then
            echo "#password for update" >>$CONFIG_FILE
            echo "PASSWORD=\"$PASSWORD\"" >>$CONFIG_FILE
        else
            echo "passwords do not match, please start over!"
        fi
    fi

    if [ "$CRON" != "" ]; then
        echo "#cronjob" >>$CONFIG_FILE
        echo "CRON=\"$CRON\"" >>$CONFIG_FILE
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
            UPDATE_IPV4=true
            echo "debug: update v4"
        else
            UPDATE_IPV4=false
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
            UPDATE_IPV6=true
            echo "debug: update v6"
        else
            UPDATE_IPV6=false
            echo "debug: no update v6"
        fi
    fi
}

function dyndnsCF() {

    if [ "$UPDATE_IPV4" == true ] || [ "$UPDATE_IPV6" == true ]; then
        # Get Zone ID
        CF_ZONE_ID=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN&status=active" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "X-Auth-Email: $CF_API_EMAIL" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )

        # Get Record ID
        CF_RECORD_ID_IPV4=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )
    fi
    # Update IPv4
    if [[ ($STACK == "v4" || $STACK == "DS") && $UPDATE_IPV4 == true ]]; then
        # Get Record ID
        CF_RECORD_ID_IPV4=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )

        # Update DNS
        RESULTV4=$(
            curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID_IPV4" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"A\",\"name\":\"$SUBDOMAIN\",\"content\":\"$CURRENT_IPV4\",\"ttl\":1,\"proxied\":false}"
        )
    fi
    echo "$RESULTV4"
    # Update IPv6
    if [[ ($STACK == "v6" || $STACK == "DS") && $UPDATE_IPV6 == true ]]; then
        # Get Record ID
        CF_RECORD_ID_IPV6=$(
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=AAAA&name=$SUBDOMAIN.$DOMAIN" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id'
        )

        # Update DNS
        RESULTV6=$(
            curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID_IPV6" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"AAAA\",\"name\":\"$SUBDOMAIN\",\"content\":\"$CURRENT_IPV6\",\"ttl\":1,\"proxied\":false}"
        )
    fi
    echo "$RESULTV6"
    # Check Update
    if [ "$RESULTV4" == *"\"success\":false"* ]; then
        echo "$RESULTV4"
        echo "debug: there was an error updating your dynamic DNS"
    fi

    if [ "$RESULTV6" == *"\"success\":false"* ]; then
        echo "$RESULTV6"
        echo "debug: there was an error updating your dynamic DNS"
    fi

}

function dyndnsStrato() {

    # Update DNS
    if [ $STACK == "v4" ] && [ $UPDATE_IPV4 == true ]; then
        RESULT="$(curl --silent --show-error "https://$DOMAIN:$PASSWORD@dyndns.strato.com/nic/update?hostname=$SUBDOMAIN.$DOMAIN&myip=$CURRENT_IPV4")"
        echo "debug: v4 update result: "$RESULT

    elif [ $STACK == "v6" ] && [ $UPDATE_IPV6 == true ]; then
        RESULT="$(curl --silent --show-error "https://$DOMAIN:$PASSWORD@dyndns.strato.com/nic/update?hostname=$SUBDOMAIN.$DOMAIN&myip=$CURRENT_IPV6")"
        echo "debug: v6 update result: "$RESULT

    elif [ $STACK == "DS" ] && ([ $UPDATE_IPV4 == true ] || [ $UPDATE_IPV6 == true ]); then
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
    crontab -l | grep -q $FILE && CRONSTATUS=true && echo 'debug: a cronjob exist' || CRONSTATUS=false

    # Check if the cronjob has changed
    CRONJOB=$(crontab -l | grep -i $FILE)
    if [ "$CRONJOB" == "${CRON} ${FILE}" ]; then
        echo "debug: cron is up to date"
        CRONUPDATE=false
    elif [ "$CRONSTATUS" ] && [ "$CRON" == "" ]; then
        crontab -l >CRONJOB
        echo "debug: remove cronjob"
        sed_file=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<<"$FILE")
        sed -i "\%$sed_file%d" "CRONJOB"
        crontab CRONJOB
        rm CRONJOB
    else
        echo "debug: cron in the config has changed"
        CRONUPDATE=true
    fi

    # Create or update cronjob
    if [ "$CRONSTATUS" == false ] && [ "$CRON" != "" ]; then
        echo "debug: install Cronjob"
        crontab -l >CRONJOB
        echo "${CRON}" "${FILE}" >>CRONJOB
        crontab CRONJOB
        rm CRONJOB
    elif [ "$CRONSTATUS" == true ] && [ "$CRONUPDATE" == true ] && [ "$CRON" != "" ]; then
        echo "debug: update Cronjob"
        crontab -l | grep -v $FILE | crontab -
        crontab -l >CRONJOB
        echo "${CRON}" "${FILE}" >>CRONJOB
        crontab CRONJOB
        rm CRONJOB
    fi
}

function changeCron() {
    echo ""
    read -e -p "Cronjob [Default: Every 5 Minutes]: " -i "*/5 * * * *" CRON
    if grep -q "CRON=" "$CONFIG_FILE"; then
        sed -i "s#^CRON=.*#CRON=\"${CRON}\"#" "$CONFIG_FILE"
        echo "Cron replaced."
    else
        echo "#cronjob" >>$CONFIG_FILE
        echo "CRON=\"$CRON\"" >>$CONFIG_FILE
        echo "Cron added."
    fi
}

# Loop through all the command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --cron)
        CRON_FLAG=true
        ;;
    --configfile)
        CONFIG_PATH="$2"
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

source $CONFIG_PATH
CONFIG_FILE=$CONFIG_PATH

if [ -f "$CONFIG_FILE" ]; then

    if [ "$CRON_FLAG" == true ]; then
        changeCron
    fi

    echo "debug: $CONFIG_FILE exists"
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
