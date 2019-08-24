#!/usr/bin/env bash

# Utility Daemon by Keegan Bowen
# traprestart function to keep the daemon running as much as we can
traprestart()
{
$0 "$$" &
exit 0
}
trap traprestart HUP TERM INT
# Run like this:
# nohup./util-daemon.sh /your/filesystem/ 10 &
# The "10" is the loop rate in seconds. Ten is okay on most systems.
UDIR="$1"

mkdir -p $UDIR/log
touch $UDIR/util.sleep
echo $3 > $UDIR/util.sleep

# Do reporting with these congfiguration files. 
# They need to be in place.
# Edit the config files with comma delimited search regrexes.
# Example for blacklist.conf:
# facebook.com, otherplace, 192.168.1.22
# This will not stop facebook.com, just let you know that the server is connected to it.
# The mother-daemon.sh can react to the output for further processing, including
# killing the connection.

# Each config only takes up to three entries. If you need more, expand the greps!
# Edit line 74 to set the desired email address.

# Alert for specific network connections
touch $UDIR/blacklist.conf
# Check on a network processes
touch $UDIR/netp.conf
# Look for a process to be stopped
touch $UDIR/killproc.conf
# Check for a running proess
touch $UDIR/procp.conf

gather() {
    df -h > $UDIR/df.out
    uptime > $UDIR/uptime.out
    netstat -a | grep -v unix > $UDIR/netstat.out
    ps aux > $UDIR/ps.out
}

report() {

ly=$(which lynis)

if [ -z "$ly" ]; then
    lynis && cp /var/log/lynis-report.dat $UIDR/log/
else
    echo "No lynis installed!" > $UDIR/log/lynis.warn
fi

    grep [9][7-9]% $UDIR/df.out > $UDIR/log/df.warn
    grep "100%" $UDIR/df.out > $UDIR/log/df.alert
    grep keeper-daemon.sh $UDIR/ps.out > $UDIR/log/keeper.warn
    grep install-daemon.sh $UDIR/ps.out > $UDIR/log/install.warn
    grep mother-daemon.sh $UDIR/ps.out > $UDIR/log/mother.warn
    grep util-daemon.sh $UDIR/ps.out > $UDIR/log/util.warn
    grep cop-daemon.sh $UDIR/ps.out > $UDIR/log/cop.warn
    PROCLIM=$(cat /proc/cpuinfo | grep processor | wc -l)
    grep [["$PROCLIM"-9]][0-9].[0-9][0-9] $UDIR/uptime.out > $UDIR/log/load.warn
    grep [1-9][0-9][0-9].[0-9][0-9] $UDIR/uptime.out > $UDIR/log/load.alert
    grep [1-9][0-9][0-9][0-9].[0-9][0-9] $UDIR/uptime.out > $UDIR/log/load2.alert
    grep [1-9][0-9][0-9][0-9][0-9].[0-9][0-9] $UDIR/uptime.out > $UDIR/log/load3.alert
    grep $(cat $UDIR/blacklist.conf | cut -d',' -f1) $UDIR/netstat.out > $UDIR/log/blacklist.warn
    grep $(cat $UDIR/netp.conf | cut -d',' -f1) $UDIR/netstat.out > $UDIR/log/netp.log
    grep $(cat $UDIR/killproc.conf | cut -d',' -f1) $UDIR/ps.out > $UDIR/log/killproc.warn
    grep $(cat $UDIR/procp.conf | cut -d',' -f1) $UDIR/ps.out > $UDIR/log/procp.log
    grep $(cat $UDIR/blacklist.conf | cut -d',' -f2) $UDIR/netstat.out > $UDIR/log/blacklist2.warn
    grep $(cat $UDIR/netp.conf | cut -d',' -f2) $UDIR/netstat.out > $UDIR/log/netp2.log
    grep $(cat $UDIR/killproc.conf | cut -d',' -f1) $UDIR/ps.out > $UDIR/log/killproc.warn
    grep $(cat $UDIR/procp.conf | cut -d',' -f1) $UDIR/ps.out > $UDIR/log/procp.log
    grep $(cat $UDIR/blacklist.conf | cut -d',' -f2) $UDIR/netstat.out > $UDIR/log/blacklist2.warn
    grep $(cat $UDIR/netp.conf | cut -d',' -f2) $UDIR/netstat.out > $UDIR/log/netp2.log
    grep $(cat $UDIR/killproc.conf | cut -d',' -f2) $UDIR/ps.out > $UDIR/log/killproc2.warn
    grep $(cat $UDIR/procp.conf | cut -d',' -f2) $UDIR/ps.out > $UDIR/log/procp2.log
    grep $(cat $UDIR/blacklist.conf | cut -d',' -f3) $UDIR/netstat.out > $UDIR/log/blacklist3.warn
    grep $(cat $UDIR/netp.conf | cut -d',' -f3) $UDIR/netstat.out > $UDIR/log/netp3.log
    grep $(cat $UDIR/killproc.conf | cut -d',' -f3) $UDIR/ps.out > $UDIR/log/killproc3.warn
    grep $(cat $UDIR/procp.conf | cut -d',' -f3) $UDIR/ps.out > $UDIR/log/procp3.log
}

email() {
    echo "Utility Daemon Report $(date) from $(uname -a)" > $UDIR/logreport
    cat $UDIR/log/* >> $UDIR/logreport
#
#          SET THE EMAIL BY EDITING THE SCRIPT HERE--------------------------------------------------
#                                                                                                   |
#                                                                                                  \ /
#                                                                                                   V
    echo "$(cat $UDIR/logreport)" | mailx -s "Utility Daemon Report $(date)" example@someplace.com
}

touch $UDIR/email.send

# If there is anything in email.send, emails will be sent continously! 
# It can be a lot of emails. Use with caution.
# Example way to use the email.send file:
# echo 1 > $UDIR/email.send && sleep 300 && cp /dev/null $UDIR/email.send
# That sends emails for five minutes then stops them. Something like that could be used in a cron entry etc.

checkemail() {
if [ -s $UDIR/email.send ]
then
     echo "EMAILING REPORT"
     email
else
    gather
    report
fi
}

while true; do
    gather
    report & # If one of the greps hangs, the daemon just moves on...
    checkemail
    sleep $(cat $UDIR/util.sleep)
done

# Set the sleep amount in seconds by placing a number in $UDIR/util.sleep:wq
