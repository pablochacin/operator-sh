#!/bin/bash
source ./screenplay.sh

connect "my-session"
clean
type "# This is a screenplay library demo"
sleep 2
type "# You can automate multiple actions. Let's see."
clean 3 
type "# You can split the screen"
sleep 3
split
next
type "# And move between windows"
sleep 3
remove
clean 1
type "# You can also split vertically"
sleep 3
vsplit
sleep 3
remove
type "# check the README.md for more information"
clean 5
terminate
