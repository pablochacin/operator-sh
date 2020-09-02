#!/bin/bash

source ../lib/test.sh
source ../operator.sh

# Test invalid argument option
Test "parse_args --invalid-option"
assert_command_rc 1
assert_output_contains "Invalid parameter"
assert_output_contains "--invalid-option"
assert_output_contains "Usage"

# Test missing required argument
Test "parse_args"
assert_command_rc 1
assert_output_contains "Missing argument"
assert_output_contains "Object type"
assert_output_contains "Usage"

# Test object type is parsed
MY_OBJECT="my-object"
Test "parse_args -o $MY_OBJECT"
assert_command_rc 0
assert_output_contains "OBJECT_TYPE=$MY_OBJECT" 

# Test queue name is parsed
QUEUE_NAME="/tmp/$(uuidgen)"
Test "parse_args -o my-object --queue $QUEUE_NAME"
assert_command_rc 0
assert_output_contains "EVENT_QUEUE=$QUEUE_NAME"

# Test namespace is parsed
MY_NAMESPACE="my-namespace"
Test "parse_args -o my-object -n $MY_NAMESPACE"
assert_command_rc 0
assert_output_contains "NAMESPACE=$MY_NAMESPACE"

# Test kubeconfig is parsed
MY_KUBECONFIG="/path/to/my/kubeconfig"
Test "parse_args -o my-object -k $MY_KUBECONFIG"
assert_command_rc 0
assert_output_contains "KUBECONFIG=$MY_KUBECONFIG"

# Test changes-only is parsed
Test "parse_args -o my-object --changes-only"
assert_command_rc 0
assert_output_contains "CHANGES_ONLY=true"

# Test reset-queuw is parsed
Test "parse_args -o my-object --reset-queue"
assert_command_rc 0
assert_output_contains "RESET_QUEUE=true"

# Test log-events is parsed
Test "parse_args -o my-object --log-events"
assert_command_rc 0
assert_output_contains "LOG_EVENTS=true"

# Test log-file is parsed
set -x
LOG_FILE="/path/to/log/file"
Test "parse_args -o my-object --log-file $LOG_FILE"
assert_command_rc 0
assert_output_contains "LOG_FILE=$LOG_FILE"

# Test default queue is created
eval $(parse_args -o OBJECT)
assert_not_null $EVENT_QUEUE
Test "create_queue"
assert_command_rc 0
assert_file_exists $EVENT_QUEUE

# Test queue with given name is created
QUEUE_NAME="/tmp/queue-$(uuidgen)"
eval $(parse_args -o OBJECT -q $QUEUE_NAME)
assert_not_null $EVENT_QUEUE
Test "create_queue"
assert_command_rc 0
assert_file_exists $QUEUE_NAME
rm -f $QUEUE_NAME

echo "succeeded"

