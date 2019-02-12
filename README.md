five-daemon-mgmt
================

If you can, use selinux and something like puppet or ansible instead of these tools.

If you do need to use these, or something like them, make sure you have enough system resources allocated and tune the sleep values based on the situation. 

...

These five shell daemons install, enforce, report, and maintain unix systems.

This set of daemons requires configuration. Take a look at each script and make sure it is tuned
for your system before you run it. Running these daemons is generally a bad idea unless you are needing to
very quickly do something very specific... think of it this way:

If you need to ensure a system configuration during a short to mid term period (like less than 6 months)
and you have limited access to install new software (firewalls, bureaucracy, etc) but you have root access, 
and very little time to complete, these tools can be used very quickly without any system change requirements
to lock up and ensure various conditions.



chmod +x ./five-daemon-installer ./start-all.sh

sudo ./five-daemon-installer

sudo ./start-all.sh
