#!/bin/bash

# This is a simple script to check the public IP address of this machine vs the IP address in DNS and send a telegram message if its wrong.

# This script assumes that the following software is installed and configured correctly:
# curl
# nslookup
# logger

# User Options
opt_FriendlyName=""                             # This name will appear in the message
opt_TelegramBotToken=""                         # Token of Telegram Bot
opt_TelegramMessageID=""                        # ID of the Telegram conversation to post the alert to
opt_AlertTimeoutSeconds="43200"                 # Alerts wont go out within these seconds of the last email
opt_DNSserver=""                                # Server to check DNS records, use the web server most likely
opt_DNSname=""                                  # (sub)domain to check the IP address for
opt_IPcheckServer="https://icanhazip.com"	# Service for checking IP address, should return ONLY the IP

file_AlertFile="/dev/shm/.dns-ip-check.txt"	# Full path to the file where the last message is stored
opt_Debug=""                                    # Debug setting, if off then nothing will print to logs on success

# Script Begins
if [ "$1" == "debug" ]; then
 opt_Debug="True"
fi

var_DNSreply=$(nslookup $opt_DNSname $opt_DNSserver |grep "Address:" |grep -v '#53' |awk '{print $2}')
var_IPreply=$(curl -s $opt_IPcheckServer)

str_FailureMessage="dns-ip-check.sh: $opt_FriendlyName IP does NOT match DNS entry. $opt_DNSname is: ($var_DNSreply). $opt_IPcheckServer returns ($var_IPreply) as public IP."
str_SuccessMessage="dns-ip-check.sh: $opt_FriendlyName IP matches DNS entry. $opt_DNSname resolves to $var_DNSreply. $opt_IPcheckServer returns $var_IPreply as public IP."

str_GenerateJSON=$(cat <<EOF 
{"chat_id": "$opt_TelegramMessageID", "text": "$str_FailureMessage"}
EOF
)

function fn_TriggerMessage {
str_CurlTelegram=$(curl -s -X POST -H "Content-Type: application/json" -d "$str_GenerateJSON" https://api.telegram.org/bot$opt_TelegramBotToken/sendMessage)
}

if [ "$var_DNSreply" == "$var_IPreply" ]; then
 if [ -n "$opt_Debug" ]; then
  logger -s $str_SuccessMessage
  fn_TriggerMessage
 fi
else
 if [ -e $file_AlertFile ]; then
  var_CurrentEpoch=$(date +%s)
  var_AlertEpoch=$(stat -c %Y $file_AlertFile)
  if [ $(($var_CurrentEpoch - $var_AlertEpoch)) -gt $opt_AlertTimeoutSeconds ]; then
   logger -s $str_FailureMessage |tee
   fn_TriggerMessage
  fi
 else
  logger -s $str_FailureMessage
  fn_TriggerMessage
 fi
fi