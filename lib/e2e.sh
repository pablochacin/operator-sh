# Library with functions to help in operator e2e tests

source lib/test.sh

# Starts the operator with the (optional) arguments in $1
# capturing the resulting log in the E2E_OPERATOR_LOG variable.
# The operator is executed with a set of hooks in the test/hooks directory 
# unless otherwise specified in the operator's arguments ($2)
#
# TODO: Create a namespace for each test
function e2e_start_operator(){
    E2E_OPERATOR_LOG_FILE=$(mktemp /tmp/operator-XXXX.log)
    # get temp filename, but don't create file
    E2E_OPERATOR_QUEUE=$(mktemp /tmp/operator-XXX.queue -u)

    # start operator in background 
    ./operator.sh -h tests/hooks $E2E_OPERATOR_ARGS -l $E2E_OPERATOR_LOG_FILE -q $E2E_OPERATOR_QUEUE &
    E2E_OPERATOR_PID=$!
    
    # check operator started correctly
    ps --no-header $E2E_OPERATOR_PID > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "${TEST_CONTEXT@P} operator failed to start"
        exit 1
    fi

    test_set_env E2E_OPERATOR_LOG_FILE $E2E_OPERATOR_LOG_FILE
    test_set_env E2E_OPERATOR_QUEUE $E2E_OPERATOR_QUEUE
    test_set_env E2E_OPERATOR_PID $E2E_OPERATOR_PID
}

# terminate operator and cleanup 
function e2e_stop_operator(){
    E2E_OPERATOR_PID=$(test_get_env "E2E_OPERATOR_PID")
    E2E_OPERATOR_LOG_FILE=$(test_get_env "E2E_OPERATOR_LOG_FILE")
    E2E_OPERATOR_QUEUE=$(test_get_env "E2E_OPERATOR_QUEUE")

    kill $E2E_OPERATOR_PID 2>&1 > /dev/null 
    E2E_OPERATOR_LOG=$(cat $E2E_OPERATOR_LOG_FILE)
    test_set_env E2E_OPERATOR_LOG $E2E_OPERATOR_LOG
    rm -f $E2E_OPERATOR_LOG_FILE 2>&1 > /dev/null
    rm -f $E2E_OPERATOR_QUEUE
}   

# assert if test log does not contains a string
function e2e_assert_log_does_not_contain(){
    E2E_OPERATOR_LOG=$(test_get_env "E2E_OPERATOR_LOG")
    if [[ $E2E_OPERATOR_LOG == *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Failed log does not contain $1"
        exit 1
    fi
}

# assert if test output contains a string
function e2e_assert_log_contains(){
    E2E_OPERATOR_LOG=$(test_get_env "E2E_OPERATOR_LOG")
    if [[ $E2E_OPERATOR_LOG != *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed log does not contain $1"
        exit 1
    fi
}


# check the kind cluster is active
# TODO: Automatically create cluster if not already created
function e2e_check_cluster_active(){
    if [[ -z "$(kind get clusters)" ]]; then
        echo "${TEST_CONTEXT@P} test setup failed: no clusters defined"
        exit 1
    fi
}

E2E_OPERATOR_PID=
E2E_OPERATOR_OPS=
E2E_OPERATOR_LOG_FILE=
E2E_OPERATOR_QUEUE=
E2E_OPERATOR_LOG=
E2E_OPERATOR_ARGS=
