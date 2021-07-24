#!/bin/bash

source lib/log.sh

# Watch events in k8s using kubectl
#
# Get objects and watch for events in json format. The events are sent
# to a queue for processing.
function watch(){
    local NS_FLAG=${NAMESPACE:+"-n ${NAMESPACE}"}
    local WATCH_ONLY_FLAG=$(if $CHANGES_ONLY; then echo "--watch-only"; fi)
    local KUBECONFIG_FLAG=${KUBECONFIG:+"--kubeconfig $KUBECONFIG"}
    local CONTEXT_FLAG=${CONTEXT:+"--context $CONTEXT"}
    local LS_FLAG=${LABEL_SELECTOR:+"--selector $LABEL_SELECTOR"}

    while true; do
        kubectl $KUBECONFIG_FLAG $CONTEXT_FLAG get $OBJECT_TYPE --watch -o json --output-watch-events $LS_FLAG $NS_FLAG $WATCH_ONLY_FLAG >> $EVENT_QUEUE 
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
        log_warning "Error parsing event"
        log_warning $EVENT_ENV
        return
    fi
    # execute handler in its own environment
    (
    eval $EVENT_ENV

    # select handler based on event type
    HANDLER=${EVENT_TYPE//\"/}
    HANDLER=${HANDLER,,}
    HANDLER=${HOOKS}/${HANDLER}
    if [[ ! -e $HANDLER ]]; then
        log_debug "No event handler exits for event $EVENT_TYPE. Ignoring."
        return
    fi

    # Pass log file to allow handlers to append messages to the log
    export "LOG_FILE=$LOG_FILE" 
    export "LOG_LEVEL=$LOG_LEVEL"

    # Pass kubeconfig to allow handles to interact with the cluster using kubectl
    export "KUBECONFIG=$KUBECONFIG"

    # set env for hook
    if [[ ! -z $HOOK_ENV ]]; then
        export ${HOOK_ENV/,/ }
    fi

    # execute handler
    exec $HANDLER
    )
}


# Process events from events queue
function process(){

    while read -r EVENT ; do 
        if $LOG_EVENTS; then
            log_info $EVENT
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

# prints usage help
function usage(){

cat <<EOF

    Watch for events and process them using scripts

    Usage: $0 [OPTIONS...]

    Options
    -c,--changes-only: do not received ADDED events for existing objects
    --context: kubeconfig context
    -e,--log-events: log received events to log file
    -E,--hook-env: environment variables for hooks
    -h,--hooks: path to hooks. Default is ./hooks
    --label-selector: watch objects that match the given label(s).
      Supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)
    -l,--log-file: path to the log. Default is /var/log/operator-sh.log
    -L,--log-level: log level ("DEBUG", "INFO", "WARNING", "ERROR") 
    -k,--kubeconfig: path to kubeconfig file for accessing Kubernetes cluster
    -n,--namespace: namespace to watch (optional)
    -o,--object: type of object to watch
    -q,--queue: queue to store events
    -r,--reset-queue: reset queue to delete any pending event from previous executions
    -R,--reset-log: reset log delete messages from previous executions
    -s,--filter-spec: filter object spec from event
    -S,--filter-status: filter object status from event
    --help: display this help

EOF

}

# Parse command line arguments 
function parse_args(){
    CHANGES_ONLY=false
    EVENT_QUEUE="/tmp/k8s-event-queue"
    HOOK_ENV=
    RESET_QUEUE=false
    RESET_LOG=false
    KUBECONFIG=$KUBECONFIG
    CONTEXT=
    NAMESPACE=
    OBJECT_TYPE=
    LOG_EVENTS=false
    LOG_FILE="/var/log/operator-sh.log"
    LOG_LEVEL=LOG_LEVEL_INFO
    HOOKS="hooks"
    FILTER_SPEC=
    FILTER_STATUS=
    LABEL_SELECTOR=

    while [[ $# != 0 ]] ; do
        case $1 in
            -c|--changes-only)
                CHANGES_ONLY=true
                ;;
            --context)
                CONTEXT=$2
                shift
                ;;
            -e|--log-events)
                LOG_EVENTS=true
                ;;
            -E|--hook-env)
                HOOK_ENV=$2	
                shift
                ;;
            -h|--hooks)
                # ensure to remove the last '/' if any 
                HOOKS=${2%/}
                shift
                ;;
            --label-selector)
                LABEL_SELECTOR="$2"
                shift
                ;;
            -l|--log-file)
                LOG_FILE=$2
                shift
                ;;
            -L|--log-level)
                LOG_LEVEL=$(log_get_level $2)
                shift
                ;;
            -k|--kubeconfig)
                KUBECONFIG=$2
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
    echo "HOOK_ENV=$HOOK_ENV"
    echo "RESET_QUEUE=$RESET_QUEUE"
    echo "RESET_LOG=$RESET_LOG"
    echo "NAMESPACE=$NAMESPACE"
    echo "KUBECONFIG=$KUBECONFIG"
    echo "CONTEXT=$CONTEXT"
    echo "LOG_EVENTS=$LOG_EVENTS"
    echo "LOG_FILE=$LOG_FILE"
    echo "LOG_LEVEL=$LOG_LEVEL"
    echo "HOOKS=$HOOKS"
    echo "FILTER_STATUS=$FILTER_STATUS"
    echo "FILTER_SPEC=$FILTER_SPEC"
    echo "LABEL_SELECTOR=\"$LABEL_SELECTOR\""
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
    watch &
    WATCH_PID=$!
    process & 
    PROCESS_PID=$!

    trap "exit" INT TERM
    trap "kill $WATCH_PID $PROCESS_PID" EXIT

    wait
}

## if sourced, do not execute main logic
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main $@
fi
