#!/bin/bash

source ../lib/test.sh
source ../operator.sh

#test invalid argument option
test "parse_args --invalid-option"
assert_command_rc 1
assert_output_contains "Invalid parameter"
assert_output_contains "--invalid-option"
assert_output_contains "Usage"

#test missing required argument
test "parse_args"
assert_command_rc 1
assert_output_contains "Missing argument"
assert_output_contains "Object type"
assert_output_contains "Usage"

echo "succeeded"

