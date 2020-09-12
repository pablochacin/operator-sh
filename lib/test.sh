# assert if test output does not contains a string
function assert_output_does_not_contain(){
    if [[ $TEST_COMMAND_OUTPUT == *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Failed output does not contain $1"
        exit 1
    fi
}

# assert if test output contains a string
function assert_output_contains(){
    if [[ $TEST_COMMAND_OUTPUT != *"$1"* ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed output does not contain $1"
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
    if [[ $TEST_RC != 0 ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: command '$TEST_COMMAND' returned '$TEST_RC' expected '0'"
        exit 1
    fi
}

# assert if the last command returned a value
function assert_command_rc_is_not_ok(){
    if [[ $TEST_RC == 0 ]]; then
        echo "${TEST_CONTEXT@P} Assertion failed: command '$TEST_COMMAND' returned unexpected value '0'"
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
    TEST_COMMAND_OUTPUT=$(eval "$1 2>&1 < $TEST_INPUT")
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
            IGNORE_ERRORS=" || true"
        fi
        TEST_BEFORE_EACH="$TEST_BEFORE_EACH;$1$IGNORE_ERRORS"
    else
        TEST_BEFORE_EACH=""
    fi
}

# Sets a command to be executed after each test
# Test execution is stopped on command error if "--fail-on-error" flag is specificed
# If called multiple times, the commands are executed in the
# order of the calls. To reset the command list, call without arguments
function after_each(){
    local IGNORE_ERRORS=" || true"
    if [[ ! -z "$1" ]]; then
        if [[ "$2" == "--ignore-errors" ]]; then
            IGNORE_ERRORS=""
        fi
        TEST_AFTER_EACH="$TEST_AFTER_EACH;$1$IGNORE_ERRORS"
    else
        TEST_AFTER_EACH=""
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
# The test command output is captured in the TEST_COMMAND_OUTPUT variable and the
# return code in TEST_RC.
#
function e2e_test(){
    local IFS=';'
    local SKIP_TEST=

    # if name of caller function starts with "test_"
    if [[ "${FUNCNAME[1]}" =~ ^test_.* ]]; then
        TEST_NAME="${FUNCNAME[1]}"
    else
        TEST_NAME=
    fi
  
    for BEFORE_EACH_CMD in ${TEST_BEFORE_EACH/;}; do  
        (eval "$BEFORE_EACH_CMD" > $TEST_OUTPUT 2>&1)
        if [[ $? -ne 0 ]]; then
            TEST_RC=1
            echo "${TEST_CONTEXT@P} before each command failed: $BEFORE_EACH_CMD"
            cat $TEST_OUTPUT
            SKIP_TEST=true
            break
        fi
        sleep $TEST_WAIT
    done

    # execute command
    if [[ -z "$SKIP_TEST" ]]; then
        TEST_COMMAND=$1
        TEST_COMMAND_OUTPUT=
        TEST_LOG=
        TEST_COMMAND_OUTPUT=$(eval "$TEST_COMMAND" 2>&1)
        TEST_RC=$?
        sleep $TEST_WAIT
    fi

    for AFTER_EACH_CMD in ${TEST_AFTER_EACH/;}; do 
        (eval "$AFTER_EACH_CMD" > $TEST_OUTPUT 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "${TEST_CONTEXT@P} after each command failed: '$AFTER_EACH_CMD'"
            cat $TEST_OUTPUT
        fi
        sleep $TEST_WAIT
    done
}


function usage(){
cat <<EOF

    run tests in the current script

    options:
        -t,--tests: list of test functions to run, separated by ","

EOF
}

# parse arguments
function parse_args(){

    TESTS=
    while [[ $# != 0 ]]; do
        case $1 in
            -t|-tests)
                # Replace ',' by ' '
                TESTS=${2/,/ /}
                shift
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

    echo "TESTS=$TESTS"
} 


# get a variable from the test environment
function test_get_env(){
    if [[ -e $TEST_ENV ]]; then
        grep $1 $TEST_ENV | cut -d '=' -f 2
    fi
}

# set a variable int test environment
function test_set_env(){
    local ENV=""

    # remove variable form test environment is already exists
    if [[ -e $TEST_ENV ]]; then
        ENV=$(grep -v "$1=" $TEST_ENV)
    fi
    echo "$ENV" > $TEST_ENV
    echo "$1=$2" >> $TEST_ENV
}

# template for output with the test context. To use in messages should be expanded as ${TEST_CONTEXT@P}
TEST_CONTEXT="[\$(caller)] \${TEST_NAME:+[\$TEST_NAME] }"

TEST_BEFORE_EACH=""
TEST_AFTER_EACH=""
TEST_WAIT=10

# Executes tests in the current script
function test_runner(){

    ARGS=$(parse_args $@)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    eval $ARGS

    # get list of test functions
    TEST_LIST=$(grep $0 -e '^function test_*' | grep -o -e 'test_[a-zA-Z0-9\_\-]*')
    
    # execute tests
    if [[ -z $TEST_LIST ]]; then
        echo "No tests detected in $0"
        exit 1
    fi

    echo "Executing tests"
    for TEST in $TEST_LIST; do
        # skip if not selected 
        if [[ ! -z $TESTS ]] && [[ ! ${TESTS[@]} =~ $TEST ]]; then
            continue
        fi
        echo "  $TEST"
        ( 
            TEST_ENV=$(mktemp /tmp/test-XXXX.env)
            TEST_OUTPUT=$(mktemp /tmp/test-XXXX.out)
            TEST_COMMAND=
            TEST_COMMAND_OUTPUT=
            TEST_RC=

            $TEST 

            rm -rf $TEST_ENV
            rm -rf $TEST_OUTPUT
        )
    done
    echo "Fineshed"
}
