#!/bin/bash
# Respond with a webpage with the private IP of the instance which is part of the ASG.
# The webpage also shows that it was possible for the ASG instances to establish outbound 
# internet connections with other servers through the NAT-Gateway. Otherwise the output of
# both the `yum` command and the `ping` should show a failure.

HTML_FILE_NAME="/var/www/index.html"

mkdir -p /var/www
touch ${HTML_FILE_NAME}

echo "<h1>Hostname: $(hostname -f)</h1>" > ${HTML_FILE_NAME}

YUM_RESULT_TEXT=""
YUM_COMMAND_OUTPUT=$(yum upgrade-minimal)
yum upgrade-minimal && YUM_RESULT_TEXT="yum worked!"
echo "<h2> yum command: </h2>" >> ${HTML_FILE_NAME}
echo "<p><b>${YUM_RESULT_TEXT}</b></p>" >> ${HTML_FILE_NAME}
echo "<p>${YUM_COMMAND_OUTPUT}</p>" >> ${HTML_FILE_NAME}

PING_TEST=$(ping -i 2 -c 5 google.de)
echo "<h2> PING Test: </h2>" >> ${HTML_FILE_NAME}
echo "<p>${PING_TEST}</p>" >> ${HTML_FILE_NAME}

cd /var/www
python3 -m http.server 80
