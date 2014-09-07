#!/bin/bash -c

# Cop Daemon by Keegan Bowen
# Enforce system users to only those on the list.

# Dependancies: deluser
####################################################################
####################################################################
####################################################################
####################################################################
#################
#################    WARNING!
#################    If an error happens while running this script,
#################    your system could be ruined.
#################    Run on a QA virtual machine first..

# /var/tmp/cop-daemon/users.list is the file that contains this list.
# If you like the current users in your system, run this:

# cat /etc/passwd | cut -d':' -f1 > /var/tmp/cop-daemon/users.list

# Protect your users.list, access to that file negates the security of this daemon.
# The keeper daemon can be used to help, just point it to /var/tmp/cop-daemon/users.list
# rather than at /var/tmp/cop-daemon because that would make a mess!

# This daemon should be run as root or a cop-daemon user which has full deluser permissions.
# I recommend /var/tmp/cop-daemon/cop-daemon.sh > /dev/null 2>&1 &

mkdir -p /var/tmp/cop-daemon/delusers/
cd /var/tmp/cop-daemon/
cat /var/tmp/cop-daemon/users.list | while read user;
   do id "$user" > "$user".out;
   cp "$user".out user.backup
done;

function usergrep () {
cat /etc/passwd | cut -d':' -f1 | while read currentusers; do
      grep "$currentusers" *.out > "$currentusers"
      echo "$currentusers" > /var/tmp/cop-daemon/delusers/"$currentusers"
done
}

function uservalidate () {
for realusers in $(cat /var/tmp/cop-daemon/users.list); do
  rm /var/tmp/cop-daemon/delusers/"$realusers";
done
}

function checker () {
usergrep &&
uservalidate
}

function userremove () {
ls /var/tmp/cop-daemon/delusers/ > /var/tmp/cop-daemon/delusers.out
while read removeduser; do
    deluser -f "$removeduser";
done</var/tmp/cop-daemon/delusers.out
}

while true; do
    checker
    userremove
    sleep $(cat cop.sleep);
done
