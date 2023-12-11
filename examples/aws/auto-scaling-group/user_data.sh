#!/bin/bash
mkdir /var/www
touch /var/www/index.html
echo "<h1>Hostname: $(hostname -f)</h1>" > /var/www/index.html
cd /var/www
python3 -m http.server 80
