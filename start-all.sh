#!/bin/bash

# After each daemon is configured, you can start the whole family with this script:
# sudo ./start-all.sh

echo "Starting up the Five Daemon MGMT group..."
cd /var/tmp/cop-daemon/
nohup /var/tmp/cop-daemon/cop-daemon.sh &
cd /var/tmp/util-daemon/
nohup /var/tmp/util-daemon/util-daemon.sh &
cd /var/tmp/keeper-daemon/
# The keeper daemon can have multiple configs, hadoop2 is just an example here.
# Add your own configs and instances in!
nohup /var/tmp/keeper-daemon/keeper-daemon.sh hadoop2 &
cd /var/tmp/install-daemon/
nohup /var/tmp/install-daemon/install-daemon.sh &
cd /var/tmp/mother-daemon/
nohup /var/tmp/mother-daemon/mother-daemon.sh &

echo "Starup complete.
