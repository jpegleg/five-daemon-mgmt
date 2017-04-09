#!/bin/bash
# Install Daemon by Keegan Bowen
# Manage installation on a large list of servers from a single console.

# Edit the server-list.conf for the servers you want to push code to
# with this daemon. You will need to manage the yum repo yourself.
# Edit deps.conf with the software in your yum repo that the daemon
# will install.

# Daemon mode, check for deps.conf updates:
differ() {
  diff check.out check.last > trigger.file
}

checker () {
  touch check.last
  stat deps.conf | grep Modify | cut -d':' -f2,3 > check.out;
  differ
  cp check.out check.last
}

# Pass the scripts configuration to a file to be transferred to each server.
cat deps.conf > args.install

# Loop through the configuration file and update each server when
# trigger.file contains data which should only happen when
# the deps.conf is updated.

serverloop() {
    for x in $(cat /var/tmp/install-daemon/server-list.conf); do
        ssh -q "$x" "mkdir -p /var/tmp/install-daemon/; exit"
        scp args.install "$x"://var/tmp/install-daemon/
        ssh "$x" "cat /var/tmp/install-daemon/args.install | while read entry; do apt-get install --assume-yes "$entry"; done && exit"
    done
}

main() {
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
    sleep $(cat /var/tmp/install-daemon/installer.sleep);
done
