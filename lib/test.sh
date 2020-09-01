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


# Executes the command passed as argument and captures the output and the rc
function test(){
    TEST_COMMAND="$1"
    TEST_OUTPUT=$($1 2>&1)
    TEST_RC=$?
}


TEST_COMMAND=
TEST_OUTPUT=
TEST_RC=

