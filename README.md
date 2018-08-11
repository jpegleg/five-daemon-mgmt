five-daemon-mgmt
================

These five shell daemons install, enforce, report, and maintain unix systems.

This set of daemons requires configuration. Take a look at each script and make sure it is tuned
for your system before you run it. Running these daemons is generally a bad idea unless you are needing to
very quickly do something very specific.

chmod +x ./five-daemon-installer ./start-all.sh

sudo ./five-daemon-installer

sudo ./start-all.sh
