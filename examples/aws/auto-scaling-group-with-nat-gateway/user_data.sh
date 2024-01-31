#!/bin/bash
# # TODO: update comment
# Respond with a webpage with the private IP of the instance on port 80.
mkdir /var/www
touch /var/www/index.html
PING_TEST=$(ping -c 1 google.de) || return
echo "<h1>Hostname: $(hostname -f)</h1>" > /var/www/index.html
echo ${PING_TEST} >> /var/www/index.html
cd /var/www
ping -c 1 google.de && python3 -m http.server 80

