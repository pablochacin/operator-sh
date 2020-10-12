#!/bin/bash

source screencasts/screenplay.sh

connect "demo"
clean
type "# This is a screenplay library demo"
pause 2
type "# You can automate multiple actions. Let's see."
clean 3 
type "# You can split the screen"
pause 3
split
next
type "# And move between windows"
pause 3
remove
clean 1
type "# You can also split vertically"
pause 3
vsplit
pause 3
remove
type "# check the README.md for more information"
clean 5
terminate
