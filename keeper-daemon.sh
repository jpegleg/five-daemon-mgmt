#!/bin/bash
# Keeper Daemon by Keegan Bowen, 2014
#
#  Set two configuration files in /var/tmp/keeper-daemon/
#  One is for your thread, for example "user-archive" needs a file called keeper-user-archive.conf
#  In that file place one entry to protect and one to remove:
#  PRT /usr/local/archive
#  DSY /tmp/bloat
# 
#  Then run the daemon like so:
#  ./keeper-daemon.sh user-archive &> /var/log/keeper-daemon.log &
# Or skip the logging:
# ./keeper-daemon.sh user-archive >/dev/null &

DSY=$(grep DSY /var/tmp/keeper-daemon/keeper-"$@".conf|cut -d' ' -f2)
PRT=$(grep PRT /var/tmp/keeper-daemon/keeper-"$@".conf|cut -d' ' -f2)
SESH=$(date +"%m-%d-%y-%s")

mkdir -p /var/tmp/keeper-daemon/backup-"$SESH"

function keep () {
    rm -rf "$DSY"
    rm -f "$DSY"
    scp -r "$PRT"/ /var/tmp/keeper-daemon/backup-"$SESH"/ 
    cd /var/tmp/keeper-daemon/
    tar czvf /var/tmp/keeper-daemon/"$SESH".tar.gz backup-"$SESH"/
    rm -rf /var/tmp/keeper-daemon/backup-"$SESH"
}

function checker () {
    cd /var/tmp/keeper-daemon/
    touch check.last
    ls -lrth "$PRT"/ > check.out
    diff check.out check.last > trigger"$SESH".file;
    cat check.out > check.last;
}

function restore () {
    rm -rf "$PRT"
    mkdir -p "$PRT"
    cd /var/tmp/keeper-daemon/
    tar xzvf "$SESH".tar.gz &&
    mv -f backup-"$SESH"/*/* "$PRT"/
    cp /dev/null /var/tmp/keeper-daemon/trigger"$SESH".file &&
    rm -rf "$PRT"/backup-"$SESH" 
}

function main () {
if [ -s trigger"$SESH".file ]
then
     echo "ESTABLISHING CONTENT"
     echo "$SESH" "$PRT" data
     echo "at $(date)"
     restore
     echo ".........ESTABLISHED"
else
     checker
fi
}

keep

while true; do
    checker
    main
    rm -rf "$DSY"
    rm -f "$DSY"
    sleep $(cat /var/tmp/keeper-daemon/keeper.sleep)
done
  

# Run the keeper only on file systems containing only files that don't need to be accessed continously 
# by running applications. File archives, repositories, and clustered servers are all great targets for the keeper.
# If you run this on a production cluster server that requires manual or precision failovers, I recommend
# building a command for the failover into the restore function. 
