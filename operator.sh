#!/bin/bash

# prints usage help
function usage(){

cat <<EOF 
    
    Watch for events and process them using scripts

    Usage: $0 [OPTIONS...]

    Options
    -a,--added: path to handler for ADDED events
    -d,--deleted: path to handler for DELETED events 
    -e,--log-events: log received events to log file
    -l,--log-file: path to the log
    -k,--kubeconfig: path to kubeconfig file for accessing Kubernetes cluster
    -m,--modified: path to handler for MODIFIED events
    -n,--namespace: namespace to watch (optional)
    -o,--object: type of object to watch
    -q,--queue: queue to store events
    -r,--reset-queue: reset queue to delete any pending event from previous executions
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
   EVENT_ENV=$($SCRIPT_DIR/parse.py 2>>$LOG_FILE)

   # execute handler in its own environment
   (
    export $EVENT_ENV

    # select handler based on event type
    # TODO: use an associative array to simplify logic and inderect variable substitution
    HANDLER=${EVENT_TYPE//\"/}"_HANDLER"
    HANDLER_SCRIPT=${!HANDLER}
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
# Remove existing queue, if --reset-queue option was specified 
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
    KUBECONFIG=$KUBECONFIG
    NAMESPACE=
    OBJECT_TYPE=
    LOG_EVENTS=false
    LOG_FILE="/tmp/k8s-events.log"
    ADDED_HANDLER="hooks/added.sh"
    MODIFIED_HANDLER="hooks/modified.sh"
    DELETED_HANDLER="hooks/deleted.sh"

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
            -h|--help)
                usage >&2
                exit 0
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
    echo "NAMESPACE=$NAMESPACE"
    echo "KUBECONFIG=$KUBECONFIG"
    echo "LOG_EVENTS=$LOG_EVENTS"
    echo "LOG_FILE=$LOG_FILE"
    echo "ADDED_HANDLER=$ADDED_HANDLER"
    echo "MODIFIED_HANDLER=$MODIFIED_HANDLER"
    echo "DELETED_HANDLER=$DELETED_HANDLER"

}

# main logic
function main(){

    # parse arguments returned by the parse_args function
    ARGS=$(parse_args $@)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    eval $ARGS

    # Ensure the log file exits to facilitate tail -f it
    if [[ ! -e $LOG_FILE ]]; then
        touch $LOG_FILE
    fi

    create_queue

    # start sub-process and wait
    watch &
    process & 
    wait
}

## if sourced, do not execute main logic
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main $@
fi
