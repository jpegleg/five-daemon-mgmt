#!/bin/bash -c
# Keeper daemon, ensure key programs and files are in place.
# By Keegan Bowen

# Use keeper-servers.conf as a line by line list of servers to check on.
# Use keeper-example-server-name.conf as a list of file systems at example-server-name
# to check on. Set keeper.sleep to the check interval in seconds, the default is 45. 

function checker () {
for server in $(cat keeper-servers.conf); do
    ssh "$server" "mkdir -p /var/tmp/keeper-daemon"
    scp keeper-"$server".conf "$server"://var/tmp/keeper-daemon/
    ssh "$server" "cd /var/tmp/keeper-daemon/;
        touch check.last;
        stat $(cat /var/tmp/keeper-daemon/keeper*conf) | grep Modify | cut -d':' -f2,3 >> check.out;
        diff check.out check.last > trigger.file;
        cp check.out check.last; exit;"
    scp "$server":/var/tmp/keeper-daemon/trigger.file ./"$server"\>trigger
done
}

# You can't have the > symbol in your server name with this setup.
function serverloop () {
for server in $(ls "$server"\>trigger | cut -d'>' | -f1); do
    cat keeper-"$server".conf | while read "$system"; do
        scp -r "$server"-backup/"$server"-"$system"-backup/ "$server":/"$system"
done
}

function rotation () {
    for x in $(cat keeper-servers.conf); do
    server="$x";
    main;
    done;
}

function main () {
if [ -s "$server".trigger ]
then
     echo "CORE CHANGES DETECTED"
     echo "....................."
     serverloop
     echo ".............REVERTED"
else
     checker
fi
}

# When the daemon starts, a system backup is made. 
for server in $(cat keeper-servers.conf); do
   for system in $(cat "$server".conf); do
       mkdir -p "$server"-backup/"$server"-$system"-backup/
       scp -r "$server":/"$system" "$server"-backup/"$server"-"$system"-backup/
       done
done
# Run the checker once to set the files.
checker

# As long as the daemon is running, it will defend the original backup.

while true; do 
    rotation;
    sleep $(cat keeper.sleep)
done
