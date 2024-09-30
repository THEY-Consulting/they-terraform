#!/bin/bash

# Install the EFS mount helper
yum install amazon-efs-utils -y

# Create a mount point for the EFS file system
mkdir /mnt/efs

# Mount the EFS file system
# https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-helper-ec2-linux.html
# TODO: use variable for EFS ID and region
# mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport FILE_SYSYEM_ID.efs.AWS_REGION.amazonaws.com:/ /mnt/efs

# Respond with a webpage with the private IP of the instance on port 80.
mkdir /var/www
touch /var/www/index.html
echo "<h1>Hostname: $(hostname -f)</h1>" > /var/www/index.html
cd /var/www
python3 -m http.server 80
