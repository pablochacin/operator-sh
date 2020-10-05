# Screen casts

## screenplay library
`screenplay.sh` libray offers a series of functions for creating scripted screen casts.

Example:


Create a simple script
```

#!/bin/bash
source ./screenplay.sh

SCREEN_SESSION="my-session"

clean
send "# This is a screenplay library demo"
sleep 2
send "# You can automate multiple actions. Let's see."
clean 3 
send "# You can split the screen"
sleep 5
split
next
send "# And move between windows"
sleep 5
remove
send "# You can also split vertically"
sleep 5
vsplit
sleep 5
remove
clean
send "# check the README.md for more information"
```

From one terminal starts a new screen session 
```
$ screen -S my-session
```

