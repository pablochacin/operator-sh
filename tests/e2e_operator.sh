#!/bin/bash

source lib/test.sh

# Ensure there are no active deployments before tests starts
kubectl delete deployment --all 2>&1 > /dev/null

# cleat up deployments after each test
after_each "kubectl delete deployment --all --wait=true"

# set a wait of 10 seconds before test steps to avoid timing issues
test_wait 10

# Test ADDED events are received for new pods created 
e2e_test "kubectl create deployment nginx --image nginx"  "-o pod -L INFO"
assert_command_rc 0
assert_log_contains "Processing event ADDED"

# Test ADDED events are received for existing pods
kubectl create deployment nginx --image nginx
e2e_test "kubectl get deployment nginx" "-o pod -L INFO"
assert_command_rc 0
assert_log_contains "Processing event ADDED"

echo "succeded"
