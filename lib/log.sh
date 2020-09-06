export LOG_LEVEL_DEBUG=0
export LOG_LEVEL_INFO=1
export LOG_LEVEL_WARNING=2
export LOG_LEVEL_ERROR=3

export LOG_LEVEL=${LOG_LEVEL:-LOG_LEVEL_INFO}
export LOG_FILE=${LOG_FILE:-/dev/stderr}

# writes a message to the LOG_FILE if the current log level defined in LOG_LEVEL
# is above the message level defined in $1
function log(){
    local LEVEL=$1
    shift

    local LOG_LEVELS=( "DEBUG" "INFO" "WARNING" "ERROR" )
   
    if [[ ${LEVEL} -lt $LOG_LEVEL ]]; then
        return
    fi
    
    local TIME_STAMP=$(date +'%Y-%m-%d %H:%M:%S')

    echo -e "$TIME_STAMP ${LOG_LEVELS[${LEVEL}]} $@" >> $LOG_FILE
}

# returns the log level given its name. If invalid, null is returned
# TODO: validate name (decide what to do if invalid)
function log_get_level(){
    local LEVEL="LOG_LEVEL_${1^^}"
    echo ${!LEVEL}
}

shopt -s expand_aliases
alias log_debug='log 0' 
alias log_info='log 1'
alias log_warning='log 2'
alias log_error='log 3'

