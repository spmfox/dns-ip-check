#!/bin/bash

# This is a simple script to check the public IP address of this machine vs the IP address in DNS and send an email if it is wrong.

# This script assumes that the following software is installed and configured correctly:
# sSMTP
# curl
# nslookup
# logger


# User Options
opt_Debug="no"                                  # Debug setting, if off then nothing will print to logs on success
opt_DNSserver=""                                # Server to check DNS records, use the web server most likely
opt_DNSname=""                                  # (sub)domain to check the IP address for
opt_IPcheckServer=""                            # Service for checking IP address, should return ONLY the IP
opt_EmailTo=""                                  # Email to
opt_EmailFrom=""                                # Email from
opt_EmailSubject=""                             # Email subject
file_MessageFile=""                             # File name for the temporary email file
opt_EmailTimeoutSeconds=""                      # Emails wont go out within these seconds of the last email

dir_WorkingDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $dir_WorkingDir

# Script Begins
var_DNSreply=$(nslookup $opt_DNSname $opt_DNSserver |grep "Address:" |grep -v '#53' |awk '{print $2}')
var_IPreply=$(curl -s $opt_IPcheckServer)

if [ -z "$var_DNSreply" ] || [ -z "$var_IPreply" ]; then
 exit
fi

str_FailureMessage="dns-ip-check.sh - IP does NOT match DNS entry. $opt_DNSname resolves to $var_DNSreply / $opt_IPcheckServer returns $var_IPreply as public IP."
str_SuccessMessage="dns-ip-check.sh - IP matches DNS entry. $opt_DNSname resolves to $var_DNSreply / $opt_IPcheckServer returns $var_IPreply as public IP."

if [ "$var_DNSreply" == "$var_IPreply" ]; then
 if [ "$opt_Debug" == "yes" ]; then
  logger $str_SuccessMessage
 fi
else
 if [ -e $file_MessageFile ]; then
  var_CurrentEpoch=$(date +%s)
  var_EmailEpoch=$(stat -c %Y $file_MessageFile)
  if [ $(($var_CurrentEpoch - $var_EmailEpoch)) -gt $opt_EmailTimeoutSeconds ]; then
   logger $str_FailureMessage
   printf "From: $opt_EmailFrom\nTo: $opt_EmailTo\nSubject: $opt_EmailSubject\n\n $str_FailureMessage" > $file_MessageFile
   /usr/sbin/ssmtp $opt_EmailTo < $file_MessageFile
  fi
 else
  logger $str_FailureMessage
  printf "From: $opt_EmailFrom\nTo: $opt_EmailTo\nSubject: $opt_EmailSubject\n\n $str_FailureMessage" > $file_MessageFile
  /usr/sbin/ssmtp $opt_EmailTo < $file_MessageFile
 fi
fi
