#!/bin/bash

# Utility Daemon by Keegan Bowen, 2014

# Run like this:
# nohup./util-daemon.sh &

mkdir -p /var/tmp/util-daemon/log

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
touch /var/tmp/util-daemon/blacklist.conf
# Check on a network processes
touch /var/tmp/util-daemon/netp.conf
# Look for a process to be stopped
touch /var/tmp/util-daemon/killproc.conf
# Check for a running proess
touch /var/tmp/util-daemon/procp.conf


function gather () {
    df -h > /var/tmp/util-daemon/df.out
    uptime > /var/tmp/util-daemon/uptime.out
    netstat -a | grep -v unix > /var/tmp/util-daemon/netstat.out
    ps aux > /var/tmp/util-daemon/ps.out
}

function report () {
    grep [9][7-9]% /var/tmp/util-daemon/df.out > /var/tmp/util-daemon/log/df.warn
    grep "100%" /var/tmp/util-daemon/df.out > /var/tmp/util-daemon/log/df.alert
    grep keeper-daemon.sh /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/keeper.warn
    grep install-daemon.sh /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/install.warn
    grep mother-daemon.sh /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/mother.warn
    grep util-daemon.sh /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/util.warn
    grep cop-daemon.sh /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/cop.warn
    PROCLIM=$(cat /proc/cpuinfo | grep processor | wc -l)
    grep [["$PROCLIM"-9]][0-9].[0-9][0-9] /var/tmp/util-daemon/uptime.out > /var/tmp/util-daemon/log/load.warn
    grep [1-9][0-9][0-9].[0-9][0-9] /var/tmp/util-daemon/uptime.out > /var/tmp/util-daemon/log/load.alert
    grep [1-9][0-9][0-9][0-9].[0-9][0-9] /var/tmp/util-daemon/uptime.out > /var/tmp/util-daemon/log/load2.alert
    grep [1-9][0-9][0-9][0-9][0-9].[0-9][0-9] /var/tmp/util-daemon/uptime.out > /var/tmp/util-daemon/log/load3.alert
    grep $(cat /var/tmp/util-daemon/blacklist.conf | cut -d',' -f1) /var/tmp/util-daemon/netstat.out > /var/tmp/util-daemon/log/blacklist.warn
    grep $(cat /var/tmp/util-daemon/netp.conf | cut -d',' -f1) /var/tmp/util-daemon/netstat.out > /var/tmp/util-daemon/log/netp.log
    grep $(cat /var/tmp/util-daemon/killproc.conf | cut -d',' -f1) /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/killproc.warn
    grep $(cat /var/tmp/util-daemon/procp.conf | cut -d',' -f1) /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/procp.log
    grep $(cat /var/tmp/util-daemon/blacklist.conf | cut -d',' -f2) /var/tmp/util-daemon/netstat.out > /var/tmp/util-daemon/log/blacklist2.warn
    grep $(cat /var/tmp/util-daemon/netp.conf | cut -d',' -f2) /var/tmp/util-daemon/netstat.out > /var/tmp/util-daemon/log/netp2.log
    grep $(cat /var/tmp/util-daemon/killproc.conf | cut -d',' -f2) /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/killproc2.warn
    grep $(cat /var/tmp/util-daemon/procp.conf | cut -d',' -f2) /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/procp2.log
    grep $(cat /var/tmp/util-daemon/blacklist.conf | cut -d',' -f3) /var/tmp/util-daemon/netstat.out > /var/tmp/util-daemon/log/blacklist3.warn
    grep $(cat /var/tmp/util-daemon/netp.conf | cut -d',' -f3) /var/tmp/util-daemon/netstat.out > /var/tmp/util-daemon/log/netp3.log
    grep $(cat /var/tmp/util-daemon/killproc.conf | cut -d',' -f3) /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/killproc3.warn
    grep $(cat /var/tmp/util-daemon/procp.conf | cut -d',' -f3) /var/tmp/util-daemon/ps.out > /var/tmp/util-daemon/log/procp3.log
}

function email () {
    echo "Utility Daemon Report $(date) from $(uname -a)" > /var/tmp/util-daemon/logreport
    cat /var/tmp/util-daemon/log/* >> /var/tmp/util-daemon/logreport
#
#          SET THE EMAIL BY EDITING THE SCRIPT HERE------------------------------------------------
#                                                                                                   |
#                                                                                                  \ /
#                                                                                                   V
    echo "$(cat /var/tmp/util-daemon/logreport)" | mailx -s "Utility Daemon Report $(date)" example@someplace.com
}

touch /var/tmp/util-daemon/email.send

# If there is anything in email.send, emails will be sent continously! 
# It can be a lot of emails. Use with caution.
# Example way to use the email.send file:
# echo 1 > /var/tmp/util-daemon/email.send && sleep 300 && cp /dev/null /var/tmp/util-daemon/email.send
# That sends emails for five minutes then stops them. Something like that could be used in a cron entry etc.

function checkemail () {
if [ -s /var/tmp/util-daemon/email.send ]
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
    sleep $(cat /var/tmp/util-daemon/util.sleep)
done

# Set the sleep amount in seconds by placing a number in /var/tmp/util-daemon/util.sleep
