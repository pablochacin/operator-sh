#!/bin/bash

source lib/test.sh

# Test invalid argument option
function test_invalid_argument(){
    unit_test "./parse.py --invalid"
    assert_command_rc_is_not_ok
    assert_output_contains "unrecognized arguments"
    assert_output_contains "--invalid"
}

# Test default parsing
function test_default_parsing(){
    unit_test "./parse.py" "tests/event.json"
    assert_command_rc_is_ok
    assert_output_contains "EVENT_TYPE="
    assert_equals 74 $(wc -l <<< $TEST_OUTPUT)
}

# Test filter status 
function test_filter_status(){
    unit_test "./parse.py --no-status" "tests/event.json"
    assert_command_rc_is_ok
    assert_output_does_not_contain "STATUS"
    # output is not empty
    assert_not_equals 0 $(wc -l <<< $TEST_OUTPUT)
}

# Test filter spec
function test_filter_spect(){
    unit_test "./parse.py --no-spec" "tests/event.json"
    assert_command_rc_is_ok
    assert_output_does_not_contain "SPEC"
    # output is not empty
    assert_not_equals 0 $(wc -l <<< $TEST_OUTPUT)
}

test_runner
