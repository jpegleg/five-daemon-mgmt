#!/bin/bash
# Mother daemon collects system information and five-daemon-mgmt information and reacts.
#  Keep things running with the traprestart function.
#
traprestart()
{
$0 "$$" &
exit 0
}
trap traprestart HUP TERM INT
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

checkall() {
coppidval=$(pgrep cop-daemon.sh)
if [ -z $coppidval ]; then
    touch /var/tmp/mother-daemon/cop.pid
    ps auxwww | grep /var/tmp/cop-daemon/cop-daemon.sh$ | awk '{print $2}' | head -n1 > /var/tmp/mother-daemon/cop.pid
else
    touch /var/tmp/mother-daemon/cop.pid
    echo $coppidval > /var/tmp/mother-daemon/cop.pid
fi
keeperpidval=$(pgrep keeper-daemon.sh)
if [ -z $keeperpidval ]; then
    touch /var/tmp/mother-daemon/keeper.pid
    ps auxwww | grep /var/tmp/keeper-daemon/keeper-daemon.sh$ | awk '{print $2}' | head -n1 > /var/tmp/mother-daemon/keeper.pid
else
    touch /var/tmp/mother-daemon/keeper.pid
    echo $keeperpidval > /var/tmp/mother-daemon/keeper.pid
fi
installpidval=$(pgrep install-daemon.sh)
if [ -z $installpidval ]; then
    touch /var/tmp/mother-daemon/install.pid
    ps auxwww | grep /var/tmp/install-daemon/install-daemon.sh$ | awk '{print $2}' | head -n1 > /var/tmp/mother-daemon/install.pid
else
    touch /var/tmp/mother-daemon/install.pid
    echo $installpidval > /var/tmp/mother-daemon/install.pid
fi
utilpidval=$(pgrep util-daemon.sh)
if [ -z $utilpidval ]; then
    touch /var/tmp/mother-daemon/util.pid
    ps auxwww | grep /var/tmp/util-daemon/util-daemon.sh$ | awk '{print $2}' | head -n1 > /var/tmp/mother-daemon/util.pid
else
    touch /var/tmp/mother-daemon/util.pid
    echo $utilpidval > /var/tmp/mother-daemon/util.pid
fi
     COPID=$(cat /var/tmp/mother-daemon/cop.pid)
     KEEPID=$(cat /var/tmp/mother-daemon/keeper.pid)
     INSTLID=$(cat /var/tmp/mother-daemon/install.pid)
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

sanitycheck() {
     date > /var/tmp/mother-daemon/log/sanity.log
     find / | xargs stat -c '%s %n' >> /var/tmp/mother-daemon/log/sanity.log
     SESH=$(date +"%m-%d-%y-%s")
     tar czvf /var/tmp/mother-daemon/log/sanity."$SESH".tar.gz /var/tmp/keeper-daemon/ &&
#    Uncomment and add an archive location:
#    scp /var/tmp/mother-daemon/sanity."$SESH".tar.gz /mnt/archive/location
     tar czvf /var/tmp/mother-daemon/sanity.catalog."$SESH".tar.gz /var/tmp/mother-daemon/sanity.log &&
#    Uncomment and add an archive location:
#    scp /var/tmp/mother-daemon/sanity.catalog."$SESH".tar.gz /mnt/archive/location
     echo "Catalogs have been archived..."
}
tcpkill() {
     cat /var/tmp/util-daemon/netstat.out >> /var/log/tcpkill.dat
}

warnresponse() {
df -h |  grep "100%" > /var/tmp/mother-daemon/full.trigger
    if [[ -s "/var/tmp/util-daemon/blacklist.warn" ]]; then
          netstat -a | grep $(cat /var/tmp/util-daemon/blacklist*) | grep -v grep | cut -d' ' -f7; tcpkill
     else
          echo "No warning response triggered."
     fi
}

alertresponse() {
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

warntrig() {
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
