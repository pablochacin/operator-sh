#!/bin/bash

source screencasts/screenplay.sh
source screencasts/vim.sh

connect "pvc-demo"
clean
grid <<EOF
demo script
operator log
EOF

type "# In this demo we will show how operator-sh can be used for provisioning"
type "# persistent volumes by watching persitent volume claims that have a node."
type "# selector."
clean 3
type "# Let's take a look at the added hook at examples/pvc."
next
type "cat examples/pvc/added"
top
pause 3
type "# It extracts some event information from the environment variables"
type "# such as the claim name, volume size and the node on which it must be created."
type "# Then it creates a job that creates the volumen in the target node."
next 
type "vim examples/pvc/manifests.sh"
# find the text Job
vim_locate "Job"
pause 3
vim_scroll_half_screen_down
pause 3
vim_scroll_half_screen_down
top
type "# Once the job has finished it creates a volume asociated with the claim"
next
# find the text Volume 
vim_locate "PersistentVolume"
pause 3
vim_scroll_half_screen_down
pause 3
vim_scroll_half_screen_down
pause 3
vim_exit
clean
top
type "# So let's see how this works.."
clean 2
type "# First, let's start a kind cluster with two nodes."
next 
type "cat examples/pvc/cluster.yaml"
clean 5
top
type "kind create cluster --config examples/pvc/cluster.yaml"
wait_key
type "kubectl cluster-info --context kind-kind"
clean 0
type "# The cluster has two worker nodes."
type "kubectl get nodes"
clean 3
type "# Now, let's start the operator for monitoring pvc events"
type "# and the event hooks from examples/pvc"
pause 3
type "./operator.sh -o pvc --hooks examples/pvc -l /tmp/operator.log -L DEBUG --filter-status &"
pause 2
next
type "# Now let's see watch the content of the log"
type "tail -f /tmp/operator.log"
top
clean 2
type "# Now we can create a pvc with a node selector on the worker-2"
type "cat examples/pvc/pvc.yaml"
clean 5
type "kubectl apply -f examples/pvc/pvc.yaml"
clean 5
type "# We should see the event in the log and also the creation of the job"
pause 3
type "kubectl get jobs"
clean 3 
type "# We should also see the persistent volume asociated to the pvc."
pause 5
type "kubectl get pv,pvc"
clean 10
type "# This demo shows how some simple automations can be implemented"
type "# using the usual tools from Kubernetes management and the operator-sh"
clean 5
type "# Before we leave, let's delete the cluster"
pause 1
type "kind delete cluster"
clean 3
type "# Thanks for your attention. "
type "# If interested in knowing more, please visit https://github.com/pablochacin/operator-sh"
pause 5
terminate
