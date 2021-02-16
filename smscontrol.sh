#!/bin/bash

source alarm.conf
TwilioSID=$Twilio_SID
TwilioAT=$Twilio_AH
TwilioDiD=$Twilio_DID
controlnumbers=($Phone_Numbers_Control)
controlusers=($Phone_Numbers_Users)

function get_messages {
	curl -X GET https://api.twilio.com/2010-04-01/Accounts/"$TwilioSID"/Messages.json?PageSize=1 \
        -u "$TwilioSID":"$TwilioAT"
}

function send_message {
        curl -X POST https://api.twilio.com/2010-04-01/Accounts/"$TwilioSID"/Messages.json \
        --data-urlencode "Body=$2" \
        --data-urlencode "From=$TwilioDiD" \
        --data-urlencode "To=$1" \
        -u "$TwilioSID":"$TwilioAT"
}

while :
do
        apianswer=$(get_messages)
        message=$(echo "$apianswer" | cut -d'{' -f 3 | cut -d':' -f 2 |  cut -d'"' -f 2)
        direction=$(echo "$apianswer" | cut -d'{' -f 3 | cut -d':' -f 4 | cut -d'"' -f 2)
        contact=$(echo "$apianswer" | cut -d'{' -f 3 | cut -d':' -f 5 | cut -d'"' -f 2)
        id=$(echo "$apianswer" | cut -d'{' -f 3 | cut -d':' -f 11 | cut -d'"' -f 2)
        message=${message,,}

        echo "------------"
        echo "$apianswer"
        echo "------------"
        echo "$message"
        echo "------------"
	echo "$direction"
        echo "------------"
        echo "$contact"
        echo "------------"
        echo "$id" 
        echo "------------"
        
		if [ "$contact" != "" ] && [ "$message" != "" ] && [ "$id" != "" ] &&  [ "$direction" = "inbound" ]; then
			c=0
			for i in "${controlnumbers[@]}"; do
			        if [ "$i" = "$contact" ]; then
                			if ls armed* > /dev/null 2>&1; then
                			        if [ "$message" = "status" ]; then
                			                send_message "$contact" "Status_Armed_by_$(find -- armed* | head -n1)"
                			                echo "status armed"
                				
                				elif [ "$message" = "arm" ]; then
                				        send_message "$contact" "Already_armed_by_$(find -- armed* | head -n1)"
                				        
                				elif [ "$message" = "disarm" ]; then
                				        rm disarmed*
                				        touch disarmed_SMS_"${controlusers[c]}"
                				        rm armed*
                				fi
                			else
                			        if [ "$message" = "status" ]; then
                			                send_message "$contact" "Status_Disarmed_by_$(find -- disarmed* | head -n1)"
                			                echo "status disarmed"
                				
                				elif [ "$message" = "arm" ]; then
                			                touch armed_SMS_"${controlusers[c]}"
                			               
                				elif [ "$message" = "disarm" ]; then
                				        send_message "$contact" "Already_Disarmed_by_$(find -- disarmed* | head -n1)"
                				fi
                			fi
                		fi
                		((c=c+1))
        		done
		fi
        	if [ "$id" != "" ]; then
                        curl -X DELETE https://api.twilio.com"$id" \
                        -u "$TwilioSID":"$TwilioAT"
                fi
        sleep 10
done
