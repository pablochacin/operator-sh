#!/bin/bash

source lib/e2e.sh

# Test ADDED events are received for new pods created
function test_new_pods(){
    E2E_OPERATOR_ARGS="-o pod -L INFO"
    test_cmd "kubectl create deployment nginx --image nginx"
    assert_command_rc 0
    e2e_assert_log_contains "Processing event ADDED"
}

# Test ADDED events are received for existing pods
function test_existing_pods(){
    kubectl create deployment nginx --image nginx > /dev/null
    E2E_OPERATOR_ARGS="-o pod -L INFO"
    test_cmd "kubectl get deployment nginx" 
    assert_command_rc 0
    e2e_assert_log_contains "Processing event ADDED"
}

# Test ADDED events are not received for existing pods
function test_not_existing_pods(){
    kubectl create deployment nginx --image nginx > /dev/null
    E2E_OPERATOR_ARGS="-o pod --changes-only -L INFO"
    test_cmd "kubectl get deployment nginx" 
    assert_command_rc 0
    e2e_assert_log_does_not_contain "Processing event ADDED"
}

# Test events only for given namespace are processed
function test_namespace(){
    E2E_OPERATOR_ARGS="-o pod -L INFO"
    test_cmd "kubectl create deployment nginx --image nginx"
    assert_command_rc 0
    e2e_assert_log_contains "Processing event ADDED"
}

# Test filter status from events
function test_filter_status(){
    E2E_OPERATOR_ARGS="-o pod -L INFO --filter-status"
    test_cmd "kubectl create deployment nginx --image nginx"
    assert_command_rc 0
    e2e_assert_log_contains "Processing event ADDED"
    e2e_assert_log_does_not_contain "EVENT_OBJECT_STATUS"
}


# Test filter spec from events
function test_filter_spec(){
    E2E_OPERATOR_ARGS="-o pod -L INFO --filter-spec"
    test_cmd "kubectl create deployment nginx --image nginx" 
    assert_command_rc 0
    e2e_assert_log_contains "Processing event ADDED"
    e2e_assert_log_does_not_contain "EVENT_OBJECT_SPEC"
}


# initialization of test suit

e2e_check_cluster_active

# Ensure there are no active deployments before tests starts
kubectl delete deployment --all 2>&1 > /dev/null

# start operator before each test, with the options set in E2E_OPERATOR_ARGS
before_each "e2e_start_operator"

# clean up deployments after each test
after_each "e2e_stop_operator"
after_each "kubectl delete deployment --all --wait=true" 
after_each "kubectl delete namespace test --wait=true" 

# set a wait of 5 seconds before test steps to avoid timing issues
test_wait 5 

test_runner $@
