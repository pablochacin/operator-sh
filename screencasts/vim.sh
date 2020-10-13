# screenplay macros for navigating a document

# find a text from the current location i
function vim_find(){
    send "/$1"
    cr
}

# place the current line on the top
function vim_place_on_top(){
    send "z"
    cr
}

# scrolls hald screen down
function vim_scroll_half_screen_down(){
    send "^d"
}

#go to top of file
function vim_top_of_file(){
    send "gg"
}

# to to botton of file
function vim_bottom_of_file(){
    send "G"
    cr
}

# move to botton of screen
function vim_top_of_screen(){
    send "^A H"
}

# move to botton of screen
function vim_botton_of_screen(){
    send "^A L"
}

# exit
function vim_exit(){
    send ":q!"
    cr
}

# move down a line
function vim_move_down(){
    send "j"
}

# move up a line
function vim_move_up(){
    send "k"
}

# find text and locate it at the top of the screen
function vim_locate(){
    vim_top_of_file
    vim_find $1
    vim_place_on_top
}

# scroll line by line up to the number of lines
# with a pause of $2 seconds between lines
function vim_roll_down(){
    local num_lines=${1:-1}
    local pause_time=${2:-0.2}
    vim_botton_of_screen
    for l in $(seq 1 $num_lines); do
        vim_move_down
        pause $pause_time
    done
}
