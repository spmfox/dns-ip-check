# dns-ip-check

## Why
The idea behind this was a poor mans Dynamic DNS. I was not happy with the solutions out there nor the services. I have a web server that hosts DNS also so I decided to write a script that would check and message me if my IP changed.

## How
The core requirement is you need a domain name to look up the IP address. Usually this would be a subdomain such as server.host.com. On this (sub)domain there should be just an A record with the IP address of the system you want to check. An example of this would be the IP address at your house. You would take this IP and create the A record on your subdomain to point to that address.

Once you have a (sub)domain pointing to your target IP address, you'll need to specify the server used to do this lookup. Normally it would be the server you created the record on. You could query the public DNS system (such as Google or Clouldflare), however there would be a delay if you ever had to change the IP in the future.

Lastly a service that will return your public IP address via the curl command. This is how we compare what your IP should be vs what it actually is.

## Telegram
I can't cover the methods of creating Bots or getting your conversation ID from Telegram because these methods may change in the future. Here are the basic steps:
1. Create Telegram Bot, get the Bot Token ID
2. Create a conversation or channel, get the ID
3. ???
4. Profit


## Variables
Here is a list of variables to edit for normal operation

| Variable | Purpose |
| ---------| ------- |
|opt_FriendlyName | This is the name that will appear in the alert message |
|opt_TelegramBotToken|Token of Telegram Bot|
|opt_TelegramMessageID|ID of the Telegram conversation to post the alert to|
|opt_AlertTimeoutSeconds|Alerts wont go out within these seconds of the last message (default is 12 hours)|
|opt_DNSserver|Server to check DNS records, use the web server most likely|
|opt_DNSname|(sub)domain to check the IP address for|
|opt_IPcheckServer|Service for checking IP address, should return ONLY the IP (defaults to https://icanhazip.com)|

## Troubleshooting
I tried to make it as simple as possible however I could have made some mistakes. You can check the following commands manually to confirm why the script is not working. Be sure to replace the variables below with your actual entries.

First thing to try is running the script in debug mode - this will make the script output and message even a successful check:
```
./dns-ip-check.sh debug
```

If that does not work, you can try to have bash show all output:
```
bash -x dns-ip-check.sh debug
```
Using the "bash -x" above may show you an error from the Telegram API, perhaps with wrong information supplied. You can use the following commands to drill further into this.

| Command | Purpose |
| ------- | ------- |
| nslookup *(opt_DNSname)* *(opt_DNSserver)*| This should return the address found for your custom (sub)domain|
| curl -s *(opt_IPcheckServer)*| This should return one line only, and it should be your public IP address|

Last thing to check is the Telegram message sender, it is possible either the Bot Token or Chat ID are wrong.
```
curl -X POST \
     -H 'Content-Type: application/json' \
     -d '{"chat_id": "(opt_TelegramMessageID)", "text": "This is a test from curl"}' \
     https://api.telegram.org/bot(opt_TelegramBotToken)/sendMessage
```
