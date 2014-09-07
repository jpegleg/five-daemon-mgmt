#!/bin/bash -c
# Install Daemon by Keegan Bowen
# Manage installation on a large list of servers from a single console.

# Edit the server-list.conf for the servers you want to push code to
# with this daemon. You will need to manage the yum repo yourself.
# Edit deps.conf with the software in your yum repo that the daemon
# will install.

# Daemon mode, check for deps.conf updates:
function differ () {
  diff check.out check.last > trigger.file
}

function checker () {
  touch check.last
  stat deps.conf | grep Modify | cut -d':' -f2,3 > check.out;
  differ
  cp check.out check.last
}

# Pass the scripts configuration to a file to be transferred to each server.
echo $(cat deps.conf) > args.install

# Loop through the configuration file and update each server when
# trigger.file contains data which should only happen when
# the deps.conf is updated.

function serverloop () {
    for x in $(cat server-list.conf); do
        ssh -q "$x" "mkdir -p /var/tmp/install-daemon/; exit"
        scp args.install "$x"://var/tmp/install-daemon/
        ssh "$x" "cat /var/tmp/install-daemon/args.install | while read entry; do yum install "$entry"; done"
    done
}

function main () {
if [ -s trigger.file ]
then
     echo "INSTALLING UPDATES"
     serverloop
else
     checker
fi
}
# The installer.sleep file controls the amount of time
# between when the install daemon diffs and pushes updates.
# The default is 100 seconds.
while true; do
    main
    sleep $(cat installer.sleep);
done
