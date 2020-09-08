#!/bin/bash

source lib/test.sh

test_wait 10 
before_each "kubectl delete deployment --all"

# test pods
e2e_test "kubectl create deployment nginx --image nginx"  "-o pod -L INFO"
assert_command_rc 0
assert_log_contains "Processing event ADDED"

echo "succeded"
