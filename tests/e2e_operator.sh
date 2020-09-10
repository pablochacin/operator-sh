#!/bin/bash

source lib/test.sh

# Test ADDED events are received for new pods created
function test_new_pods(){
    e2e_test "kubectl create deployment nginx --image nginx"  "-o pod -L INFO"
    assert_command_rc 0
    assert_log_contains "Processing event ADDED"
}

# Test ADDED events are received for existing pods
function test_existing_pods(){
    kubectl create deployment nginx --image nginx > /dev/null
    e2e_test "kubectl get deployment nginx" "-o pod -L INFO"
    assert_command_rc 0
    assert_log_contains "Processing event ADDED"
}

# Test ADDED events are not received for existing pods
function test_not_existing_pods(){
    kubectl create deployment nginx --image nginx > /dev/null
    e2e_test "kubectl get deployment nginx" "-o pod --changes-only -L INFO"
    assert_command_rc 0
    assert_log_does_not_contain "Processing event ADDED"
}

# Test events only for given namespace are processed
function test_namespace(){
    e2e_test "kubectl create deployment nginx --image nginx"  "-o pod -L INFO"
    assert_command_rc 0
    assert_log_contains "Processing event ADDED"
}


# initialization of test suit

# Ensure there are no active deployments before tests starts
kubectl delete deployment --all 2>&1 > /dev/null

# clean up deployments after each test
after_each "kubectl delete deployment --all --wait=true" --ignore-errors
after_each "kubectl delete namespace test --wait=true"  --ignore-errors

# set a wait of 10 seconds before test steps to avoid timing issues
test_wait 10

test_runner
