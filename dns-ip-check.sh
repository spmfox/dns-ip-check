#!/bin/bash
#spmfox@foxwd.com

# Bash script to check a (sub)domain, find its IP address, and compare it to the external IP on the current system.
# If they do not match, then a telegram message and/or email is sent.

# This script uses the following commands:
# curl
# nslookup

# User Options
opt_FriendlyName=""                             # This name will appear in the message
opt_TelegramBotToken=""                         # Token of Telegram Bot
opt_TelegramMessageID=""                        # ID of the Telegram conversation to post the alert to
opt_EmailServer=""				# Email SMTP server
opt_EmailFrom=""				# Email to send from
opt_EmailTo=""					# Email to send to
opt_EmailUser=""				# Username for email
opt_EmailPassword=""				# Password for email
opt_AlertTimeoutSeconds="43200"                 # Alerts wont go out within these seconds of the last alert
opt_DNSserver=""                                # Server to check DNS records, use the web server most likely
opt_DNSname=""                                  # (sub)domain to check the IP address for
opt_IPcheckServer="https://ipv4.icanhazip.com"	# Service for checking IP address, should return ONLY the IP

file_AlertFile="/dev/shm/.dns-ip-check.txt"	# Full path to the file where the last message is stored
file_AlertEmail="/dev/shm/.dns-ip-check.eml"	# Full path to the file where the email will be temporarily stored

str_DNSreply=$(nslookup $opt_DNSname $opt_DNSserver |grep "Address:" |grep -v '#53' |awk '{print $2}')
str_IPreply=$(curl -s $opt_IPcheckServer)

str_FailureMessage="dns-ip-check.sh: $opt_FriendlyName IP does NOT match DNS entry. $opt_DNSname is: ($str_DNSreply). $opt_IPcheckServer returns ($str_IPreply) as public IP."
str_SuccessMessage="dns-ip-check.sh: $opt_FriendlyName IP matches DNS entry. $opt_DNSname resolves to $str_DNSreply. $opt_IPcheckServer returns $str_IPreply as public IP."

function fn_TriggerMessage {
#Generate messages for Telegram and email
 str_GenerateJSON=$(cat <<EOF
{"chat_id": "$opt_TelegramMessageID", "text": "$str_FailureMessage"}
EOF
)
 echo $str_FailureMessage > $file_AlertFile

#Telegram message 
 if [ -n "$opt_TelegramBotToken" ] && [ -n "$opt_TelegramMessageID" ]; then
  echo "Sending Telegram message."
  str_CurlTelegram=$(curl -s -X POST -H "Content-Type: application/json" -d "$str_GenerateJSON" https://api.telegram.org/bot$opt_TelegramBotToken/sendMessage)
 else
  echo "One or both Telegram settings are missing, not sending Telegram message."
 fi

#Email message
 if [ -n "$opt_EmailServer" ] && [ -n "$opt_EmailFrom" ] && [ -n "$opt_EmailTo" ] && [ -n "$opt_EmailUser" ] && [ -n "$opt_EmailPassword" ]; then
  echo "Sending email."
  echo "From: $opt_EmailFrom" > $file_AlertEmail
  echo "To: $opt_EmailTo" >> $file_AlertEmail
  echo "Subject: $opt_FriendlyName DNS Check Alert" >> $file_AlertEmail
  echo "" >> $file_AlertEmail
  echo $str_FailureMessage >> $file_AlertEmail
  str_CurlEmail=$(curl -s --ssl-reqd smtp://$opt_EmailServer --mail-from $opt_EmailFrom --mail-rcpt $opt_EmailTo --upload-file $file_AlertEmail --user "$opt_EmailUser":"$opt_EmailPassword")
  rm $file_AlertEmail
 else
  echo "One or more email settings are missing, not sending email message."
 fi
}

if [ "$str_DNSreply" == "$str_IPreply" ]; then
 echo $str_SuccessMessage
fi

if [ -e $file_AlertFile ]; then
 var_CurrentEpoch=$(date +%s)
 var_AlertEpoch=$(stat -c %Y $file_AlertFile)
 if [ $(($var_CurrentEpoch - $var_AlertEpoch)) -gt $opt_AlertTimeoutSeconds ]; then
  echo $str_FailureMessage
  fn_TriggerMessage
 else
  echo $str_FailureMessage
  echo "Skipping alert message due to the timeout threshold not reached."
 fi
else
 echo $str_FailureMessage
 fn_TriggerMessage
fi
