#!/bin/bash
traphup()
{
$0 "$$" &
exit 0
}
trap traphup HUP TERM INT
# Mother Daemon by Keegan Bowen, 2014

# The Mother does a lot. Checks on her children ( the other daemons ) 
# Mom reacts to system warnings and does some cataloging and validation...

# You will need to configure the other daemons in the five-daemon-mgmt group
# before the mother-daemon will run properly. 
# /var/tmp/keeper-daemon/keeper-daemon.sh
# /var/tmp/util-daemon/util-daemon.sh
# /var/tmp/cop-daemon/cop-daemon.sh
# /var/tmp/install-daemon/install-daemon.sh

mkdir -p /var/tmp/mother-daemon/log
touch /var/tmp/mother-daemon/log/mother.log
cat /etc/passwd | cut -'d': -f1 > /var/tmp/cop-daemon/users.list
cat /var/tmp/cop-daemon/users.list
echo "Those are the users allowed by the cop-daemon."
if [ -s /var/tmp/util-daemon/email.send ]
then
     echo "EMAILING IS ON."
else
     echo "EMAILING IS OFF."
fi

echo "DAEMONIZING..."

function checkall () {
ps aux | grep cop-daemon.sh | grep -v grep | cut -d' ' -f6 > /var/tmp/mother-daemon/cop.pid
ps aux | grep keeper-daemon.sh | grep -v grep | cut -d' ' -f6 > /var/tmp/mother-daemon/keeper.pid
ps aux | grep install-daemon.sh | grep -v grep | cut -d' ' -f6 > /var/tmp/mother-daemon/install.pid
ps aux | grep util-daemon.sh | grep -v grep | cut -d' ' -f6 > /var/tmp/mother-daemon/util.pid
   COPID=$(cat /var/tmp/mother-daemon/cop.pid)
   KEEPID=$(cat /var/tmp/mother-daemon/keeper.pid)
   INSTLID=$(/var/tmp/mother-daemon/install.pid)
   UTILID=$(cat /var/tmp/mother-daemon/util.pid)
if [[ -s /var/tmp/mother-daemon/cop.pid ]]; then
   echo "COP PID is $COPID"
else
   echo "COP is not running."
fi 
if [[ -s /var/tmp/mother-daemon/keeper.pid ]]; then
   echo "KEEPER PID is $KEEPID"
else
   echo "KEEPER is not running."
fi 
if [[ -s /var/tmp/mother-daemon/install.pid ]]; then
   echo "INSTALL PID is $INSTLID"
else
   echo "INSTALL is not running."
fi 
if [[ -s /var/tmp/mother-daemon/util.pid ]]; then
   echo "UTIL PID is $UTILID"
else
    echo "UTIL is not running."
fi  
}



function sanitycheck () {
    date > /var/tmp/mother-daemon/log/sanity.log
    find / >> /var/tmp/mother-daemon/log/sanity.log
    SESH=$(date +"%m-%d-%y-%s")
    tar czvf /var/tmp/mother-daemon/sanity."$SESH".tar.gz /var/tmp/keeper-daemon/ &&
#   Uncomment and add an archive location:
#   scp /var/tmp/mother-daemon/sanity."$SESH".tar.gz /mnt/archive/location
    tar czvf /var/tmp/mother-daemon/sanity.catalog."$SESH".tar.gz /var/tmp/mother-daemon/sanity.log &&
#   Uncomment and add an archive location:
#   scp /var/tmp/mother-daemon/sanity.catalog."$SESH".tar.gz /mnt/archive/location
    echo "Catalogs have been archived..."
}

function tcpkill () {
   # Still working on this part...
   echo "Admin, do something about this!"
   cat /var/tmp/util-daemon/netstat.out
}

function warnresponse () {
       df -h |  grep "100%" > /var/tmp/mother-daemon/full.trigger
       if [[ -s "/var/tmp/util-daemon/blacklist.warn" ]]; then
       netstat -a | grep $(cat /var/tmp/util-daemon/blacklist*) | grep -v grep | cut -d' ' -f7; tcpkill
           else
               echo "No warning response triggered."
           fi
}


function alertresponse () {
       df -h |  grep "100%" > /var/tmp/mother-daemon/full.trigger
       if [[ -s "/var/tmp/mother-daemon/full.trigger" ]]; then
               DUTARGET=$(df -h | grep 100% | rev | cut -d'%' -f1 | rev )
               DUOPEN1=$(df -h | grep [0-6][0-9]% | rev | cut -d'%' -f1 | rev )
               DUOPEN2=$(df -h | grep [0-9]% | rev | cut -d'%' -f1 | rev )
               cp /dev/null  "$DUTARGET"/*.log &
               cp /dev/null  "$DUTARGET"/*/*.log &
               cp /dev/null  "$DUTARGET"/*/*/*.log &
               cp /dev/null  "$DUTARGET"/*/*/*/*.log &
               cp /dev/null  "$DUTARGET"/*/*/*/*/*.log &
               cp /dev/null  "$DUTARGET"/*/*/*/*/*/*.log &
               cp /dev/null /var/tmp/mother-daemon/mother.log
               mkdir -p ${DUOPEN1}/tmp-storage/
               mkdir -p ${DUOPEN2}/tmp-storage/
           else
               echo "No alert response triggered."
           fi
}


function warntrig () {
for warn in $(ls /var/tmp/util-daemon/log/*warn); do
  echo "$warn" >> /var/tmp/mother-daemon/log/mother.log
  warnresponse
done

for alert in $(ls /var/tmp/util-daemon/log/*alert); do
  echo "$alert" >> /var/tmp/mother-daemon/log/mother.log
  alertresponse
done
}


# And now the deep dark loop
sanitycheck
while true; do
    warntrig
    checkall
    sleep $(cat /var/tmp/mother-daemon/mother.sleep)
done
