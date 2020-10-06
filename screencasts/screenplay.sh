# screen automation library

# Send text to sceen followed by <enter>
function send(){
	screen -S $SCREEN_SESSION -X stuff "$1$(echo -ne '\r')"
}

# types words one at a time with a delay between them
function type(){
    for w in $1; do
	    screen -S $SCREEN_SESSION -X stuff "$w$(echo -ne ' ')"
        sleep ${2:-0.1}
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

# Move to the next window to the left-down)
function next(){
    cmd "focus" "next"
}

# Move to the next window to the left-down)
function prev(){
    cmd "focus" "prev"
}


# Create a grid of windows. 
# grid <<EOF
# windows 1-1|windows 1-2
# windows 2-1|windows 2-2|windows 2-3
# windows 3
#EOF
function grid(){
    set -x
    local NUM_ROWS=
    local ROWS=
    local NUM_COLUMNS=
    local COLUMNS=

    # read rows from stdin
    mapfile ROWS
    echo "${ROWS[@]}"
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
        echo "$R $NUM_COLUMNS ${COLUMNS[@]}"

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
    set +x
}

# sets current window's title
function title(){
    cmd "title" "$1"
}

# remove current screen
function remove(){
    cmd "kill"
    cmd "remove"
    
}

# clear screen after waiting $1 seconds
function clean(){
	sleep ${1:-0}
	send "clear"
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
    cmd "quit"
}

# wait until a key is pressed
function wait_key(){
	read -n 1 -s -r -p "Press any key to continue"
}

# session name
SCREEN_SESSION=

