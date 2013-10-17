Easy Process Locker
=========

An easy way to add a lock to any script

Run this with your the script and arguments you want to run in quotes and it will manage a lockfile for you.
It will clean up orphaned lock files and prevent execution of jobs that are already running. 


Lockfiles are generated as /tmp/(command.ext)_(arguments) with only alpha-numeric characters, plus _-.= 
This way jobs that use the same command but different flags can run at the same time. 

Usage: epl.sh 'command you want to run with arguments'

Example: epl.sh '/usr/bin/who -a'
