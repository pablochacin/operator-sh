# screen automation library

# types words one at a time with a delay between them
function type(){
    for w in $1; do
	    screen -S $SCREEN_SESSION -X stuff "$w$(echo -ne ' ')"
        pause ${2:-0.1}
    done
    # remove last space and add <enter>
    screen -S $SCREEN_SESSION -X stuff "$(echo -ne '\b\r')"
}

# Execute command passed as $1 and pass any remaining argument as
# command argument
function cmd(){
    local COMMAND=$1
    shift
	screen -S $SCREEN_SESSION -X $COMMAND "$@" 
}

# Split current screen starting a new bash and optionally setting the title
function split(){
    cmd "split"
    cmd focus next
    cmd screen
    if  [[  $# -ne 0 ]]; then
        cmd title "$@"
    fi
    cmd focus prev
}

# Split current window vertically
function vsplit(){
    cmd "split" "-v"
    cmd focus next
    cmd screen
    if  [[  $# -ne 0 ]]; then
        cmd title "$@"
    fi
    cmd focus prev
}

# Move focus the next window to the right or down if in the rightmost window
function next(){
    cmd "focus" "next"
}

# Move focus to the previous window to the left or up if in the leftmost window
function prev(){
    cmd "focus" "prev"
}

# move focus to top-left window
function top(){
    cmd "focus" "top"
}

# changes focus to the first window with the given title
function focus(){
    local target=$1
    local initial=$(screen -S $SCREEN_SESSION -Q -X number)
    local name=$(screen -S $SCREEN_SESSION -Q -X title)
    while [[ "$name" != "$target" ]]; do
        # move next
        screen -S $SCREEN_SESSION -X focus next
        current=$(screen -S $SCREEN_SESSION -Q -X number)
        # check if we have turned to the initial window, then it was not found
        if [[ "$current" == "$initial" ]]; then
            return 1
        fi
        name=$(screen -S $SCREEN_SESSION -Q -X title)
    done 
    return 0
}  

# Create a grid of windows. 
# grid <<EOF
# windows 1-1|windows 1-2
# windows 2-1|windows 2-2|windows 2-3
# windows 3
#EOF
function grid(){
    local NUM_ROWS=
    local ROWS=
    local NUM_COLUMNS=
    local COLUMNS=

    # read rows from stdin
    mapfile ROWS
    NUM_ROWS=${#ROWS[@]}

    # create rows (there's one initial row)
    for R in $(seq 2 $NUM_ROWS); do
        cmd "split"
        # move to the next row and create first column 
        cmd "focus" "next"
        cmd "screen"
    done
    # return to first row
    cmd "focus" "next"
    
    # create columns for each row assume there's one initial column
    for R in $(seq 0 $(($NUM_ROWS-1))); do
        IFS='|' read -r -a COLUMNS <<< "${ROWS[$R]}"
        NUM_COLUMNS=${#COLUMNS[@]}

        #set title of first column
        cmd "title" "${COLUMNS[0]}"

        #create additional columns
        for C in $(seq 1 $(($NUM_COLUMNS-1))); do
            cmd "split" "-v"
            cmd "focus" "next"
            cmd "screen"
            cmd title "${COLUMNS[$C]}"
        done
        #move to next row
        cmd "focus" "next"
    done
}

# sets current window's title
function title(){
    cmd "title" "$1"
}


# change the heigh of the current window
function resize(){
    cmd "resize" $1
}

# remove current screen
function remove(){
    cmd "kill"
    cmd "remove"
    
}

# clear screen after waiting $1 seconds
function clean(){
	pause ${1:-0}
	type "clear"
}

# pause the script for the given time in seconds (fractions are allowed).
# Pause time defaults to 0 (no pause)
# If PLAY_SPEED is specified, it is applied to scale
# the pause time.
function pause(){
    local PAUSE_TIME=$(bc <<< "${1:-0}*$PLAY_SPEED")
    sleep $PAUSE_TIME
}

# connect to existing session
function connect(){
    SCREEN_SESSION=$1
}

# disconnect from screen session
function detach(){
    cmd "detach"
}

# terminate screen session
function terminate(){
    cmd "focus" "top"
    cmd "only"
    clean
    cmd "quit"
}

# wait until a key is pressed
function wait_key(){
	read -n 1 -s -r -p "Press any key to continue"
}

# session name
SCREEN_SESSION=

# play speed. Multiplies any pause time
PLAY_SPEED=${PLAY_SPEED:-1}
