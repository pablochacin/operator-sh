# assert if test output does not contains a string
function assert_output_does_not_contain(){
    if [[ $TEST_OUTPUT == *"$1"* ]]; then
        echo "Failed output does not contain $1"
        exit 1
    fi
}

# assert if test output contains a string
function assert_output_contains(){
    if [[ $TEST_OUTPUT != *"$1"* ]]; then
        echo "Assertion failed output does not contain $1"
        exit 1
    fi
}


# assert if the last command returned '0'
function assert_command_rc(){
    if [[ $TEST_RC != $1 ]]; then
        echo "Assertion failed: command '$TEST_COMMAND' returned '$TEST_RC' expected '$1'"
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

