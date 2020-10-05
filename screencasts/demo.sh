#!/bin/bash
source ./screenplay.sh

SCREEN_SESSION="my-session"

clean
type "# This is a screenplay library demo"
sleep 2
type "# You can automate multiple actions. Let's see."
clean 3 
type "# You can split the screen"
sleep 5
split
next
type "# And move between windows"
sleep 5
remove
type "# You can also split vertically"
sleep 5
vsplit
sleep 5
remove
clean
type "# check the README.md for more information"
