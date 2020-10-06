# Screen casts

## screenplay library
`screenplay.sh` libray offers a series of functions for creating scripted screen casts.

Example:


Create a simple script
```
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
```

From one terminal starts a new screen session 
```
$ screen -S my-session
```

## Recording your screen cast

Start the`screen` session  within [asciinema](https://asciinema.org):

```
$ asciinema rec [<recoding file>] -c "screen -S my-session"
```
The `<recoding file>` is optional. If specified, the `asciinema` recording is stored locally in the given file. Recording can be reproduced locally using the command `asciinema play <recoding file>`. It can also be uploaded using `asciinema upload <recoding file>`. See [`asciinema` documentation](https://asciinema.org/docs/usage) for more details.

Note: When using `asciinema` for recording, it is necessary to finish your screenplay with the `terminate` command, so the `screen` session is terminate and the recording is finished.
