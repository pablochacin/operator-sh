#!/bin/bash

source lib/test.sh
source operator.sh

# Test invalid argument option
function test_invalid_argument(){
    test_cmd "parse_args --invalid-option"
    assert_command_rc 1
    assert_output_contains "Invalid parameter"
    assert_output_contains "--invalid-option"
    assert_output_contains "Usage"
}

# Test missing required argument
function test_missing_object_type(){
    test_cmd "parse_args"
    assert_command_rc 1
    assert_output_contains "Missing argument"
    assert_output_contains "Object type"
    assert_output_contains "Usage"
}

# Test object type is parsed
function test_object_type_is_parsed(){
    MY_OBJECT="my-object"
    test_cmd "parse_args -o $MY_OBJECT"
    assert_command_rc 0
    assert_output_contains "OBJECT_TYPE=$MY_OBJECT" 
}

# Test queue name is parsed
function test_queue_name_is_parsed(){
    QUEUE_NAME="/tmp/$(uuidgen)"
    test_cmd "parse_args -o my-object --queue $QUEUE_NAME"
    assert_command_rc 0
    assert_output_contains "EVENT_QUEUE=$QUEUE_NAME"
}

# Test namespace is parsed
function test_namespace_is_parsed(){
    MY_NAMESPACE="my-namespace"
    test_cmd "parse_args -o my-object -n $MY_NAMESPACE"
    assert_command_rc 0
    assert_output_contains "NAMESPACE=$MY_NAMESPACE"
}

# Test kubeconfig is parsed
function test_kubeconfig_is_parsed(){
    MY_KUBECONFIG="/path/to/my/kubeconfig"
    test_cmd "parse_args -o my-object -k $MY_KUBECONFIG"
    assert_command_rc 0
    assert_output_contains "KUBECONFIG=$MY_KUBECONFIG"
}

# Test changes-only is parsed
function test_changes_only_is_parsed(){
    test_cmd "parse_args -o my-object --changes-only"
    assert_command_rc 0
    assert_output_contains "CHANGES_ONLY=true"
}

# Test reset-queue is parsed
function test_reset_queue_is_parsed(){
    test_cmd "parse_args -o my-object --reset-queue"
    assert_command_rc 0
    assert_output_contains "RESET_QUEUE=true"
}

# Test log-events is parsed
function test_log_events_is_parsed(){
    test_cmd "parse_args -o my-object --log-events"
    assert_command_rc 0
    assert_output_contains "LOG_EVENTS=true"
}

# Test log-file is parsed
function test_log_file_is_parsed(){
    LOG_FILE="/path/to/log/file"
    test_cmd "parse_args -o my-object --log-file $LOG_FILE"
    assert_command_rc 0
    assert_output_contains "LOG_FILE=$LOG_FILE"
}

# Test reset-log is parsed
function test_reset_log_is_parsed(){
    test_cmd "parse_args -o my-object --reset-log"
    assert_command_rc 0
    assert_output_contains "RESET_LOG=true"
}

# Test log-level is parsed
function test_log_level_is_parsed(){
    test_cmd "parse_args -o my-object --log-level DEBUG"
    assert_command_rc 0
    assert_output_contains "LOG_LEVEL=$LOG_LEVEL_DEBUG"
}

# Test filter-spec is parsed
function test_filter_spec_is_parsed(){
    test_cmd "parse_args -o my-object --filter-spec"
    assert_command_rc 0
    assert_output_contains "FILTER_SPEC=true"
}

# Test filter-status is parsed
function test_filter_status_is_parsed(){
    test_cmd "parse_args -o my-object --filter-status"
    assert_command_rc 0
    assert_output_contains "FILTER_STATUS=true"
}

# Test filter-status is parsed
function test_label_selector_is_parsed(){
    test_cmd "parse_args -o my-object --label-selector label=value"
    assert_command_rc 0
    assert_output_contains "LABEL_SELECTOR=\"label=value\""
}

# Test default queue is created
function test_default_queue_is_created(){
    eval $(parse_args -o OBJECT)
    assert_not_null $EVENT_QUEUE
    test_cmd "create_queue"
    assert_command_rc 0 
    assert_file_exists $EVENT_QUEUE
}

# Test queue with given name is created
function test_named_queue_is_created(){
    QUEUE_NAME="/tmp/queue-$(uuidgen)"
    eval $(parse_args -o OBJECT -q $QUEUE_NAME)
    assert_not_null $EVENT_QUEUE
    test_cmd "create_queue"
    assert_command_rc 0 
    assert_file_exists $QUEUE_NAME
    rm -f $QUEUE_NAME
}

test_wait 0
test_runner $@
