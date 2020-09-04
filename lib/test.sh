# assert if test output does not contains a string
function assert_output_does_not_contain(){
    if [[ $TEST_OUTPUT == *"$1"* ]]; then
        echo "[$(caller)] Failed output does not contain $1"
        exit 1
    fi
}

# assert if test output contains a string
function assert_output_contains(){
    if [[ $TEST_OUTPUT != *"$1"* ]]; then
        echo "[$(caller)] Assertion failed output does not contain $1"
        exit 1
    fi
}


# assert if the last command returned '0'
function assert_command_rc(){
    if [[ $TEST_RC != $1 ]]; then
        echo "[$(caller)] Assertion failed: command '$TEST_COMMAND' returned '$TEST_RC' expected '$1'"
        exit 1
    fi
}

# assert that the actual value $2 equals the expected value $1
function assert_equals(){
    if [[ "$1" != "$2" ]]; then
        echo "[$(caller)] Assertion failed: expected $1 actual $2"
        exit 1
    fi
}

# assert that the actual value $2 is not equals the expected value $1
function assert_not_equals(){
    if [[ "$1" == "$2" ]]; then
        echo "[$(caller)] Assertion failed: expected $1 actual $2"
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
            echo "[$(caller)] Assertion failed: $1 $2 $3"
            exit 1
            ;;
        *)
            echo "[$(caller)] Assertion evaluation error: $ASSERT_OUTPUT"
            exit 1
            ;;
    esac
}

# assert that the actual value $1 is not null
function assert_not_null(){
    if [[ -z "$1" ]]; then
        echo "[$(caller)] Assertion failed: actual value is null"
        exit 1
    fi
}

# assert file exits
function assert_file_exists(){
    if [[ ! -e $1 ]]; then
        echo "[$(caller)] Assertion failed: file '$1' doesn not exist"
        exit 1
    fi
}

# assert file does not exits
function assert_file_does_not_exist(){
    if [[ -e $1 ]]; then
        echo "[$(caller)] Assertion failed: file '$1' exists"
        exit 1
    fi
}


# Executes the command passed as $1 and captures the output and the rc.
# Optionally $2 specifies a file to be used as stdin for the command
#
# TODO: allow command pipes like 'cat input.txt | wc -l' as command
#       Such pipes fail. Check how the command is executed in a subshell.
function Test(){
    TEST_INPUT=${2:-"/dev/null"}
    TEST_COMMAND="$1"
    TEST_OUTPUT=$($1 2>&1 < $TEST_INPUT)
    TEST_RC=$?
}


TEST_COMMAND=
TEST_OUTPUT=
TEST_RC=

