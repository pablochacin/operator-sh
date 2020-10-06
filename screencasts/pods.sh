
#!/bin/bash
source screencasts/screenplay.sh

connect "pods-demo"
clean
grid <<EOF
demo script
operator log
EOF

type "# This is demo of operator-sh. In this demo we will show how it can"
type "# be used for monitoring pod events."
clean 3
type "# Let's take a look at the hook. It is very simple, just dumps all"
type "# environment variables to stdout"
type "cat examples/pods/added"
clean 10
type "# So let's see how this works.."
clean 2
type "# First, let's start a kind cluster and set it as the default context"
type "kind create cluster --name demo"
wait_key
clean
type "kubectl cluster-info --context kind-demo"
clean 3
type "# Now, let's start the operator for monitoring pod events"
type "# and the event hooks from examples/pods."
sleep 3
type "# Notice that we will filter the details of the event, to make it"
type "# easier to follow the output in the log."
sleep 3
type "./operator.sh -o pod --hooks examples/pods -l /tmp/operator.log -L WARNING --filter-spec --filter-status &"
sleep 1
next
type "# Now let's see watch the content of the log"
type "tail -f /tmp/operator.log"
top
clean 2
type "# Now we can create a pod. We should see the ADDED event in the log."
type "kubectl create deployment nginx --image nginx"
clean 10 
type "# Let's create another pod by increasing the number of replicas."
type "# We should see another event in the log"
sleep 2
next
cmd "clear"
top
type "kubectl scale deployment nginx --replicas 2"
clean 5
type "# Before we leave, let's delete the cluster"
sleep 1
type "kind delete cluster --name demo"
clean 3
type "# Thanks for your attention. "
type "# If interested in knowing more, please visit http://github.com/pablochacin/operator-sh"
sleep 5
terminate
