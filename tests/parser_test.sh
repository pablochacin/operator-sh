#!/bin/bash

source ../lib/test.sh

# Test invalid argument option
Test "../parse.py --invalid"
assert_command_rc 2
assert_output_contains "unrecognized arguments"
assert_output_contains "--invalid"

# Test default parsing
Test "../parse.py" "event.json"
assert_command_rc 0
assert_output_contains "EVENT_TYPE="
assert_equals 74 $(wc -l <<< $TEST_OUTPUT)

# Test filter status 
Test "../parse.py --no-status" "event.json"
assert_command_rc 0
assert_output_does_not_contain "STATUS"
# output is not empty
assert_not_equals 0 $(wc -l <<< $TEST_OUTPUT)

# Test filter spec
Test "../parse.py --no-spec" "event.json"
assert_command_rc 0
assert_output_does_not_contain "SPEC"
# output is not empty
assert_not_equals 0 $(wc -l <<< $TEST_OUTPUT)


echo "succeeded"

