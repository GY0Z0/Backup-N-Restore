#!/bin/bash
#
#   Project: Backup script
#   GNU/Linux Distro: Tested and working on Void and Debian 
#+  Packages needed: rsync and openssh
#   Architecture: Tested and working on x86-64 and aarch64

eval $(ssh-agent)
ssh-add /home/mrm/.ssh/my-servers


# Use while loop and ping the backup server.
IP="10.0.0.10"    #CHANGE THIS

# Maximum number to try
((count = 10))								

while [[ $count -ne 0 ]] ; do
    ping -c 1 $IP 2>&1 >/dev/null			# Try once.
    rt=$?
    if [[ $rt -eq 0 ]] ; then
        break		                      	# If okay, break the loop with "rt"
    fi
    ((count = count - 1))                  	# Count 1 so we don't go on forever
done

if [[ $rt -eq 0 ]] ; then                 	# Final check
    echo "Connection established.";
else
    echo "Connection failed."; 
	exit 68
fi  

# Config
DIRECTORY='backup'      
TIMESTAMP=$(date "+%Y-%m-%d-%H:%M:%S")
REMOTEUSER=mumriken     #EXAMPLE
LOCALUSER=mrm           #EXAMPLE
SSH="ssh -p 1027 -i /home/mrm/.ssh/backup-servers"


# Create backup directory
mkdir -p "/home/$LOCALUSER/$DIRECTORY/$TIMESTAMP"

# Copy local /etc directory to backup directory
cp -aR /etc "/home/$LOCALUSER/$DIRECTORY/$TIMESTAMP" 2>/dev/null >/dev/null

#set -xv
#Check entries / are there any older backups?
BACKUP_ENTRIES=$(ssh -p 1027 -i /home/mrm/.ssh/backup-servers $REMOTEUSER@$IP "ls /home/$REMOTEUSER/$DIRECTORY | wc -l")
if [ $BACKUP_ENTRIES -gt 0 ]
then
    echo "Creating snapshot..."
    LATEST=$(ssh -p 1027 -i /home/mrm/.ssh/backup-servers $REMOTEUSER@$IP "ls /home/$REMOTEUSER/$DIRECTORY | tail -1") # Will check if there is any existing backup
    $SSH $REMOTEUSER@$IP "cp -al /home/$REMOTEUSER/$DIRECTORY/$LATEST /home/$REMOTEUSER/$DIRECTORY/$TIMESTAMP 2>/dev/null >/dev/null"
fi

# Transfer the local backup to main server. rsync will only transfer changed or added files in /etc.
rsync -avEPhze "ssh -p 1027 -i /home/mrm/.ssh/backup-servers" "/home/$LOCALUSER/$DIRECTORY/$TIMESTAMP" "$REMOTEUSER@$IP:/home/$REMOTEUSER/$DIRECTORY/" # Finally back
#-avEphz

# END

exit 0
