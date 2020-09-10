# assert if test output does not contains a string
function assert_output_does_not_contain(){
    if [[ $TEST_OUTPUT == *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Failed output does not contain $1"
        exit 1
    fi
}

# assert if test output contains a string
function assert_output_contains(){
    if [[ $TEST_OUTPUT != *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed output does not contain $1"
        exit 1
    fi
}

# assert if test log does not contains a string
function assert_log_does_not_contain(){
    if [[ $TEST_LOG == *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Failed log does not contain $1"
        exit 1
    fi
}

# assert if test output contains a string
function assert_log_contains(){
    if [[ $TEST_LOG != *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed log does not contain $1"
        exit 1
    fi
}

# assert if the last command returned a value
function assert_command_rc(){
    if [[ $TEST_RC != $1 ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: command '$TEST_COMMAND' returned '$TEST_RC' expected '$1'"
        exit 1
    fi
}

# assert if the last command returned ok 
function assert_command_rc_is_ok(){
    if [[ $TEST_RC == 0 ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: command '$TEST_COMMAND' returned '$TEST_RC' expected '0'"
        exit 1
    fi
}

# assert if the last command returned a value
function assert_command_rc_is_not_ok(){
    if [[ $TEST_RC != 0 ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: command '$TEST_COMMAND' returned '0'"
        exit 1
    fi
}
# assert that the actual value $2 equals the expected value $1
function assert_equals(){
    if [[ "$1" != "$2" ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: expected $1 actual $2"
        exit 1
    fi
}

# assert that the actual value $2 is not equals the expected value $1
function assert_not_equals(){
    if [[ "$1" == "$2" ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: expected $1 actual $2"
        exit 1
    fi
}

# assert that the actual value $3 and the expected value $1 satisfy a certain condition given in $2.  
# 
# Examples assert_condition $EXPECTED "gt" $ACTUAL"
function assert_condition(){
    ASSERT_OUTPUT=$(test "$1" "$2" "$3")
    ASSERT_RC=$?
    case $ASSERT_RC in
        0)
            return
            ;;
        1)
            echo "${TEST_CONTEXT@P} Assertion failed: $1 $2 $3"
            exit 1
            ;;
        *)
            echo "${TEST_CONTEXT@P} Assertion evaluation error: $ASSERT_OUTPUT"
            exit 1
            ;;
    esac
}

# assert that the actual value $1 is not null
function assert_not_null(){
    if [[ -z "$1" ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: actual value is null"
        exit 1
    fi
}

# assert file exits
function assert_file_exists(){
    if [[ ! -e $1 ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: file '$1' doesn not exist"
        exit 1
    fi
}

# assert file does not exits
function assert_file_does_not_exist(){
    if [[ -e $1 ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: file '$1' exists"
        exit 1
    fi
}


# Executes the command passed as $1 and captures the output and the rc.
# Optionally $2 specifies a file to be used as stdin for the command
#
# TODO: allow command pipes like 'cat input.txt | wc -l' as command
#       Such pipes fail. Check how the command is executed in a subshell.
function unit_test(){
    
    # if name of caller function starts with "test_"
    if [[ "${FUNCNAME[1]}" =~ ^test_.* ]]; then
        TEST_NAME="${FUNCNAME[1]}"
    else
        TEST_NAME=
    fi
    
    TEST_INPUT=${2:-"/dev/null"}
    TEST_COMMAND="$1"
    TEST_OUTPUT=$(eval "$1 2>&1 < $TEST_INPUT")
    TEST_RC=$?
}

# Sets a command to be executed before each test.
# Test execution is stopped on command error unless the "--ignore-errors" flag is specificed
# If called multiple times, the commands are executed in the
# order of the calls. To reset the command list, call without arguments
function before_each(){
    local IGNORE_ERRORS=""
    if [[ ! -z "$1" ]]; then
        if [[ "$2" == "--ignore-errors" ]]; then
            IGNORE_ERRORS="|| true"
        fi
        TEST_BEFORE_EACH="$TEST_BEFORE_EACH$1$IGNORE_ERRORS"
    else
        TEST_BEFORE_EACH=
    fi
}

# Sets a command to be executed after each test
# Test execution is stopped on command error unless the "--ignore-errors" flag is specificed
# If called multiple times, the commands are executed in the
# order of the calls. To reset the command list, call without arguments
function after_each(){
    local IGNORE_ERRORS=""
    if [[ ! -z "$1" ]]; then
        if [[ "$2" == "--ignore-errors" ]]; then
            IGNORE_ERRORS=" || true"
        fi
        TEST_AFTER_EACH="$TEST_AFTER_EACH;$1$IGNORE_ERRORS"
    else
        TEST_AFTER_EACH=
    fi
}

# Sets the time to wait before/after test steps
# - After before_each
# - Before test command
# - After test command
# - After after_each
function test_wait(){
    TEST_WAIT=$1
}

# Setups a test environment and executes a test command. 
# 
# Starts the operator with the (optional) arguments in $1 and executes a test
# command passed in $1, capturing the resulting log in the TEST_LOG variable.
# The test command output is captured in the TEST_OUTPUT variable and the
# return code in TEST_RC.
#
# The operator is executed with a set of hooks in the test/hooks directory 
# unless otherwise specified in the operator's arguments ($2)
#
# TODO: Create a namespace for each test
# TODO: Automatically create cluster if not already created
function e2e_test(){
    local OPERATOR_ARGS=$2
    local TEST_LOG_FILE=$(mktemp /tmp/operator-XXXX.log)
    # get temp filename, but don't create file
    local TEST_QUEUE=$(mktemp /tmp/operator-XXX.queue -u)
    # field separator used for iterating over before/after test commands
    local IFS=';'

    # if name of caller function starts with "test_"
    if [[ "${FUNCNAME[1]}" =~ ^test_.* ]]; then
        TEST_NAME="${FUNCNAME[1]}"
    else
        TEST_NAME=
    fi
    
    # reset test results
    TEST_COMMAND=$1
    TEST_RC=
    TEST_OUTPUT=
    TEST_LOG=

    # check a cluster is defined
    if [[ -z "$(kind get clusters)" ]]; then
        echo "${TEST_CONTEXT@P} test setup failed: no clusters defined"
        exit 1
    fi

    for BEFORE_EACH_CMD in $TEST_BEFORE_EACH; do  
        BEFORE_EACH_OUT=$(eval "$BEFORE_EACH_CMD" 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "${TEST_CONTEXT@P} before each command failed: $BEFORE_EACH_CMD"
            echo "$BEFORE_EACH_OUT"
            exit 1
        fi
    done
    sleep $TEST_WAIT

    # start operator in background
    ./operator.sh -h tests/hooks $2 -l $TEST_LOG_FILE -q $TEST_QUEUE &
    OPERATOR_PID=$!
    
    # check operator started correctly
    ps --no-header $OPERATOR_PID > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "${TEST_CONTEXT@P} operator failed to start"
        exit
    fi

    sleep $TEST_WAIT
    TEST_OUTPUT=$(eval "$1 2>&1")
    sleep $TEST_WAIT

    TEST_RC=$?
    TEST_LOG=$(cat $TEST_LOG_FILE)

    # clean up and exit
    kill $OPERATOR_PID 2>&1 > /dev/null 
    rm -f $TEST_LOG_FILE 2>&1 > /dev/null
   
    for AFTER_EACH_CMD in $TEST_AFTER_EACH; do 
        AFTER_EACH_OUT=$(eval "$AFTER_EACH_CMD" 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "${TEST_CONTEXT@P} after each command failed: '$AFTER_EACH_CMD'"
            echo "$AFTER_EACH_OUT"
            exit 1
        fi
    done
    sleep $TEST_WAIT
}


TEST_CONTEXT="[\$(caller)] \${TEST_NAME:+[\$TEST_NAME] }"

TEST_COMMAND=
TEST_OUTPUT=
TEST_RC=
TEST_BEFORE_EACH=
TEST_AFTER_EACH=
TEST_WAIT=10


function test_runner(){

    # get list of test functions
    TEST_LIST=$(grep $0 -e '^function test_*' | grep -o -e 'test_[a-zA-Z0-9\_\-]*')
    
    # execute tests
    for TEST in $TEST_LIST; do
        echo "executing $TEST"
        $TEST
    done

    echo "fineshed"
}
