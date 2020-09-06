#!/bin/bash

# prints usage help
function usage(){

cat <<EOF 
    
    Watch for events and process them using scripts

    Usage: $0 [OPTIONS...]

    Options
    -a,--added: name of the hook for ADDED events. Default is 'added.sh'
    -d,--deleted: name of hook for DELETED events. Default is 'deleted.sh'
    -e,--log-events: log received events to log file
    -h,--hooks: path to hooks. Default is `./hooks`
    -l,--log-file: path to the log. Default is /var/log/operator-sh.log
    -k,--kubeconfig: path to kubeconfig file for accessing Kubernetes cluster
    -m,--modified: name of the hook for MODIFIED events. Default is modified.sh'
    -n,--namespace: namespace to watch (optional)
    -o,--object: type of object to watch
    -q,--queue: queue to store events
    -r,--reset-queue: reset queue to delete any pending event from previous executions
    -R,--reset-log: reset log delete messages from previous executions
    -s,--filter-spec: filter object spec from event
    -S,--filter-statis: filter object status from event
    -h,--help: display this help

EOF

}

# Watch events in k8s 
function watch(){
    local NS_FLAG=${NAMESPACE:+"-n ${NAMESPACE}"}
    local WATCH_ONLY_FLAG=$(if $CHANGES_ONLY; then echo "--watch-only"; fi)
    local KUBECONFIG_FLAG=${KUBECONFIG:+"--kubeconfig $KUBECONFIG"}

    while true; do
        kubectl $KUBECONFIG_FLAG get $OBJECT_TYPE --watch -o json --output-watch-events $NS_FLAG $WATCH_ONLY_FLAG >> $EVENT_QUEUE 
    done

}

# get path to script relative to operator's launch script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# handles an event received as stdin 
function handle_event(){
    # parse event fields as environment variables
    EVENT_ENV=$($SCRIPT_DIR/parse.py ${FILTER_SPEC:+"--no-spec"} ${FILTER_STATUS:+"--no-status"} 2>>$LOG_FILE)
    PARSER_RC=$?
    if [[ $PARSER_RC -ne 0 ]]; then
        echo "Error parsing event" >> $LOG_FILE
        echo $EVENT_ENV >> $LOG_FILE
        return
    fi
    # execute handler in its own environment
    (
    eval $EVENT_ENV

    # select handler based on event type
    # TODO: use an associative array to simplify logic and inderect variable substitution
    HANDLER=${EVENT_TYPE//\"/}"_HANDLER"
    HANDLER_SCRIPT="${HOOKS}/${!HANDLER}"
    if [[ ! -e $HANDLER_SCRIPT ]]; then
        echo "No event handler exits for event $EVENT_TYPE. Ignoring." >> $LOG_FILE
        return
    fi

    # Pass log file to allow handlers to append messages to the log
    export "LOG_FILE=$LOG_FILE" 

    # Pass kubeconfig to allow handles to interact with the cluster using kubectl
    export "KUBECONFIG=$KUBECONFIG"

    # execute handler
    exec $HANDLER_SCRIPT
    )
}


# Process events from events queue
function process(){

    while read EVENT ; do 
        if $LOG_EVENTS; then
            echo "$(date +'%y-%m-%d %H:%m:%S') $EVENT" >> $LOG_FILE
        fi
        handle_event <<< $EVENT
    done < $EVENT_QUEUE  
}

# Create a pipe for queuing observed events
# Remove existing queue, if the reset log option was specified 
function create_log(){
    # Reset log file
    if [[ $RESET_LOG ]] && [[ -e $LOG_FILE ]]; then
        rm -f $LOG_FILE
    fi

    # Ensure the log file exits to facilitate tail -f it
    if [[ ! -e $LOG_FILE ]]; then
        touch $LOG_FILE
    fi
}

# Create a pipe for queuing observed events
# Remove existing queue, if the reset queue option was specified 
function create_queue(){
    if [[ $RESET_QUEUE ]]; then 
        rm -f $EVENT_QUEUE
    fi

    if [[ ! -e $EVENT_QUEUE ]]; then 
        mkfifo $EVENT_QUEUE
    fi
}

# Parse command line arguments 
function parse_args(){
    CHANGES_ONLY=false
    EVENT_QUEUE="/tmp/k8s-event-queue"
    RESET_QUEUE=false
    RESET_LOG=false
    KUBECONFIG=$KUBECONFIG
    NAMESPACE=
    OBJECT_TYPE=
    LOG_EVENTS=false
    LOG_FILE="/var/log/operator-sh.log"
    HOOKS="hooks"
    ADDED_HANDLER="added.sh"
    MODIFIED_HANDLER="modified.sh"
    DELETED_HANDLER="deleted.sh"
    FILTER_SPEC=
    FILTER_STATUS=

    while [[ $# != 0 ]] ; do
        case $1 in
            -a|--added)
                ADDED_HANDLER=$2
                shift
                ;;
            -c|--changes-only)
                CHANGES_ONLY=true
                ;;
            -d|--deleted)
                DELETED_HANDLER=$2
                shift
                ;;
            -e|--log-events)
                LOG_EVENTS=true
                ;;
            -h|--hooks)
                # ensure to remove the last '/' if any 
                HOOKS=${2%/}
                shift
                ;;
            -l|--log-file)
                LOG_FILE=$2
                shift
                ;;
            -k|--kubeconfig)
                KUBECONFIG=$2
                shift
                ;;
            -m|--modified)
                MODIFIED_HANDLER=$2
                shift
                ;;
            -n|--namespace)
                NAMESPACE=$2
                shift
                ;;
            -o|--object)
                OBJECT_TYPE=$2
                shift
                ;;
            -q|--queue)
                EVENT_QUEUE=$2
                shift
                ;;
            -r|--reset-queue)
                RESET_QUEUE=true
                ;;
            -R|--reset-log)
                RESET_LOG=true
                ;;
            -s|--filter-spec)
                FILTER_SPEC=true
                ;;
            -S|--filter-status)
                FILTER_STATUS=true
                ;;
            --help)
                usage >&2
                exit 1
                ;;
            *)
                echo "Error: Invalid parameter ${1}" >&2
                usage >&2
                exit 1
                ;;
        esac
        shift
    done

    if [[ -z $OBJECT_TYPE ]]; then
        echo "Missing argument: Object type must be specified" >&2
        usage >&2
        exit 1
    fi 

    echo "OBJECT_TYPE=$OBJECT_TYPE"
    echo "CHANGES_ONLY=$CHANGES_ONLY"
    echo "EVENT_QUEUE=$EVENT_QUEUE"
    echo "RESET_QUEUE=$RESET_QUEUE"
    echo "RESET_LOG=$RESET_LOG"
    echo "NAMESPACE=$NAMESPACE"
    echo "KUBECONFIG=$KUBECONFIG"
    echo "LOG_EVENTS=$LOG_EVENTS"
    echo "LOG_FILE=$LOG_FILE"
    echo "HOOKS=$HOOKS"
    echo "ADDED_HANDLER=$ADDED_HANDLER"
    echo "MODIFIED_HANDLER=$MODIFIED_HANDLER"
    echo "DELETED_HANDLER=$DELETED_HANDLER"
    echo "FILTER_STATUS=$FILTER_STATUS"
    echo "FILTER_SPEC=$FILTER_SPEC"
}

# main logic
function main(){

    # parse arguments returned by the parse_args function
    ARGS=$(parse_args $@)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    eval $ARGS

    create_log

    create_queue

    # start sub-process and wait ensuring sub-processes are killed on exit
    trap "exit" INT TERM
    trap "kill 0" EXIT

    watch &
    process & 
    wait
}

## if sourced, do not execute main logic
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main $@
fi
