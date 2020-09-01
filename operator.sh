#!/bin/bash

# Parameters
NAMESPACE=
OBJECT_TYPE=
CHANGES_ONLY=
EVENT_QUEUE="/tmp/k8s-event-queue"
RESET_QUEUE=false


function usage(){

cat <<EOF
    Watch for events and process them using scripts

    Options
    -k,--kubeconfig: path to kubeconfig file for accessing Kubernetes cluster
    -n,--namespace: namespace to watch (optional)
    -o,--object: type of object to watch
    -q,--queue: queue to store events
    -r,--reset-queue: reset queue to delete any pending event from previous executions
    -h,--help: display this help

EOF

}

# Watch events in k8s 
# TODO: re-start watch after 5m timeout
function watch(){
    local NS_FLAG=${NAMESPACE:+"-n ${NAMESPACE}"}
    local WATCH_ONLY_FLAG=${CHANGES_ONLY:+"--watch-only"}
    local KUBECONFIG_FLAF=${KUBECONFIG:+"--kubeconfig $KUBECONFIG"}

    kubectl $KUBECONFIG_FLAG get $OBJECT_TYPE --watch -o json --output-watch-events $NS_FLAG $WATCH_ONLY_FLAG >> $EVENT_QUEUE 
}

# Process events
function process(){
    while read EVENT < $EVENT_QUEUE ; do 
        echo "$(date +'x%y-%m-%d %H:%m:%S') $EVENT" >> /tmp/k8s-events.log
    done  
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
    while [[ $# != 0 ]] ; do
        case $1 in
            -c|--changes-only)
                CHANGES_ONLY=true
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
            -h|--help)
                echo "$usage"
                exit 0
                ;;
            *)
                echo "Error: Invalid parameter ${2}"
                echo "${usage}"
                exit 1
                ;;
        esac
        shift
    done

    if [[ -z $OBJECT_TYPE ]]; then
        echo "Object type must be specified"
        echo "$usage"
        exit 1
    fi
}

# main logic
function main(){

    parse_args $@

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
