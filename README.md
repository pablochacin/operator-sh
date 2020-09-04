# Operator-sh

A framework for implementing Kubernetes Operators as shell scripts

## Goals
The main objective of operator-sh is to facilitate the development of kubernetes operators using approaches familiar to the Devops. 

- Flatten the learning curve for DevOps
- Test k8s automation ideas easily

To achieve these goals, the `operator-sh` framework follows the design principles below:
* Simplicity first.
* Extensibility by means of hooks and extensive configuration
* Easy to use locally, with simple drop and use setup and minimal dependencies

## Usage

```
    Watch for events and process them using scripts

    Usage: ./operator.sh [OPTIONS...]

    Options
    -a,--added: name of the hook for ADDED events. Default is 'added.sh'
    -d,--deleted: name of hook for DELETED events. Default is 'deleted.sh'
    -e,--log-events: log received events to log file
    -h,--hooks: path to hooks. Default is `./hooks`
    -l,--log-file: path to the log
    -k,--kubeconfig: path to kubeconfig file for accessing Kubernetes cluster
    -m,--modified: name of the hook for MODIFIED events. Default is modified.sh'
    -n,--namespace: namespace to watch (optional)
    -o,--object: type of object to watch
    -q,--queue: queue to store events
    -r,--reset-queue: reset queue to delete any pending event from previous executions
    -h,--help: display this help

```

## Design

The operator-sh framework architecture is described in the figure below

```
                       + - - - - - - - - - - - - - - - - - +        +----------+
    +--------+         ·  +-------+           +---------+  ·      +---------+  |
    |        |  events ·  |       |           |         |  ·    +-+------+  |  |
    |   K8s  |----------->| watch |           | process |--+--->|  Event |  |--+
    | Cluster|         ·  |       |           |         |  ·    | Handler|--+
    |        |         ·  +-------+           +---------+  ·    +--------+
    +--------+         ·       |                   ^  ^    ·
                       + - - - - - - - - - - - - - + -+- - +   +--------+
                               |   +-------------+ |  |        |  Json  |
                               +-->| event queue |-+  +------->| Parser |
                                   +-------------+             +--------+
```

The operator process consists of two sub-processes:
* watch: connects to the K8s cluster and watches for events on an object type, sending the events to a queue as a json object.
* process: reads events from the queue and process them sequentially. Each event is parsed and converted to a series of environment variables, as described en the section `Json Parsing`. These variables are used to initialize the environment for the event handling scripts.
* event handlers: each event type (ADDED, MODIFIED, DELETED) is handled by an external script provided by the user. This scripts are executed as sub-processes and received an environment with the content of the event and other setup information (for example, the path to the kubeconfig file to connect to the cluster)

### Json parsing

The events are transformed in a series of environment variables. This parser is adapted from the [k8s-operator](https://github.com/side8/k8s-operator). Consider the following json corresponding to the creation of a Pod:

```
{
  "type":"ADDED",
   "object": {
      "apiVersion":"v1",
      "kind":"Pod",
      "metadata": {
         "creationTimestamp":"2020-09-02T14:18:46Z",
         "generateName":"nginx-554b9c67f9-",
         "labels":{
            "app":"nginx",
            "pod-template-hash":"554b9c67f9"
         },
         "name":"nginx-554b9c67f9-psl7l",
         "namespace":"default",
         "ownerReferences": [
           {
             "apiVersion":"apps/v1",
             "blockOwnerDeletion":true,
             "controller":true,
             "kind":"ReplicaSet",
             "name":"nginx-554b9c67f9",
             "uid":"a46bbda8-073c-4bd1-a616-da9fbab4d7d6"
           }
         ],
         "resourceVersion":"11276",
         "selfLink":"/api/v1/namespaces/default/pods/nginx-554b9c67f9-psl7l",
         "uid":"bcdcd367-602e-4664-8980-da1dc8c94de3"
       },
     "spec":{
        "containers":[
           {
            "image":"nginx",
             "imagePullPolicy":"Always",
             "name":"nginx",
             "resources":{},
             "terminationMessagePath":"/dev/termination-log",
             "terminationMessagePolicy":"File",
             "volumeMounts":[
               {
                "mountPath":"/var/run/secrets/kubernetes.io/serviceaccount",
                "name":"default-token-r6ftr","readOnly":true
               }
             ]
           }
        ],
        "dnsPolicy":"ClusterFirst",
        "enableServiceLinks":true,
        "nodeName":"kind-control-plane",
        "priority":0,
        "restartPolicy":"Always",
        "schedulerName":"default-scheduler",
        "securityContext":{},
        "serviceAccount":"default",
        "serviceAccountName":"default",
        "terminationGracePeriodSeconds":30,
        "tolerations":[
          {
            "effect":"NoExecute",
            "key":"node.kubernetes.io/not-ready",
            "operator":"Exists","tolerationSeconds":300
          },
          {
            "effect":"NoExecute",
            "key":"node.kubernetes.io/unreachable",
            "operator":"Exists","tolerationSeconds":300
          }
        ],
        "volumes":[
          {
            "name":"default-token-r6ftr",
            "secret":{
              "defaultMode":420,
              "secretName":"default-token-r6ftr"
            }
          }
       ]
     },
     "status":{
       "conditions": [
         {
          "lastProbeTime":null,
          "lastTransitionTime":"2020-09-02T14:18:46Z",
          "status":"True",
          "type":"Initialized"
         },
         {
           "lastProbeTime":null,
           "lastTransitionTime":"2020-09-02T14:18:53Z",
           "status":"True","type":"Ready"
         },
         {
           "lastProbeTime":null,
           "lastTransitionTime":"2020-09-02T14:18:53Z",
           "status":"True","type":"ContainersReady"
         },
         {
           "lastProbeTime":null,
           "lastTransitionTime":"2020-09-02T14:18:46Z",
           "status":"True",
           "type":"PodScheduled"
         }
       ],
       "containerStatuses":[ 
         {
           "containerID":"containerd://da0ad052d7e4fc4019a60f916d36279c4edf657aec928335c086e67779e555ac",
           "image":"docker.io/library/nginx:latest",
           "imageID":"docker.io/library/nginx@sha256:b0ad43f7ee5edbc0effbc14645ae7055e21bc1973aee5150745632a24a752661",
           "lastState":{},
           "name":"nginx",
           "ready":true,
           "restartCount":0,
           "state":{
             "running":{
                "startedAt":"2020-09-02T14:18:52Z"
           }}
         }
       ],
       "hostIP":"172.17.0.2",
       "phase":"Running",
       "podIP":"10.244.0.4",
       "qosClass":"BestEffort","startTime":"2020-09-02T14:18:46Z"
     }
   }
 }
```

It will transformed to the environment variables shown bellow. Some aspects to highlight:
* Every element is named prefixing the name of all of the elements to the root of the event
* A prefix (by default, `EVENT` is added to each variable to prevent name collision with other existing variables
* Elements of arrays are referenced by their position (index)

```
EVENT_TYPE="ADDED"
EVENT_OBJECT_APIVERSION="v1"
EVENT_OBJECT_KIND="Pod"
EVENT_OBJECT_METADATA_CREATIONTIMESTAMP="2020-09-02T14:18:46Z"
EVENT_OBJECT_METADATA_GENERATENAME="nginx-554b9c67f9-"
EVENT_OBJECT_METADATA_LABELS_APP="nginx"
EVENT_OBJECT_METADATA_LABELS_POD_TEMPLATE_HASH="554b9c67f9"
EVENT_OBJECT_METADATA_NAME="nginx-554b9c67f9-psl7l"
EVENT_OBJECT_METADATA_NAMESPACE="default"
EVENT_OBJECT_METADATA_OWNERREFERENCES_0_APIVERSION="apps/v1"
EVENT_OBJECT_METADATA_OWNERREFERENCES_0_BLOCKOWNERDELETION="1"
EVENT_OBJECT_METADATA_OWNERREFERENCES_0_CONTROLLER="1"
EVENT_OBJECT_METADATA_OWNERREFERENCES_0_KIND="ReplicaSet"
EVENT_OBJECT_METADATA_OWNERREFERENCES_0_NAME="nginx-554b9c67f9"
EVENT_OBJECT_METADATA_OWNERREFERENCES_0_UID="a46bbda8-073c-4bd1-a616-da9fbab4d7d6"
EVENT_OBJECT_METADATA_RESOURCEVERSION="11276"
EVENT_OBJECT_METADATA_SELFLINK="/api/v1/namespaces/default/pods/nginx-554b9c67f9-psl7l"
EVENT_OBJECT_METADATA_UID="bcdcd367-602e-4664-8980-da1dc8c94de3"
EVENT_OBJECT_SPEC_CONTAINERS_0_IMAGE="nginx"
EVENT_OBJECT_SPEC_CONTAINERS_0_IMAGEPULLPOLICY="Always"
EVENT_OBJECT_SPEC_CONTAINERS_0_NAME="nginx"
EVENT_OBJECT_SPEC_CONTAINERS_0_TERMINATIONMESSAGEPATH="/dev/termination-log"
EVENT_OBJECT_SPEC_CONTAINERS_0_TERMINATIONMESSAGEPOLICY="File"
EVENT_OBJECT_SPEC_CONTAINERS_0_VOLUMEMOUNTS_0_MOUNTPATH="/var/run/secrets/kubernetes.io/serviceaccount"
EVENT_OBJECT_SPEC_CONTAINERS_0_VOLUMEMOUNTS_0_NAME="default-token-r6ftr"
EVENT_OBJECT_SPEC_CONTAINERS_0_VOLUMEMOUNTS_0_READONLY="1"
EVENT_OBJECT_SPEC_DNSPOLICY="ClusterFirst"
EVENT_OBJECT_SPEC_ENABLESERVICELINKS="1"
EVENT_OBJECT_SPEC_NODENAME="kind-control-plane"
EVENT_OBJECT_SPEC_PRIORITY="0"
EVENT_OBJECT_SPEC_RESTARTPOLICY="Always"
EVENT_OBJECT_SPEC_SCHEDULERNAME="default-scheduler"
EVENT_OBJECT_SPEC_SERVICEACCOUNT="default"
EVENT_OBJECT_SPEC_SERVICEACCOUNTNAME="default"
EVENT_OBJECT_SPEC_TERMINATIONGRACEPERIODSECONDS="30"
EVENT_OBJECT_SPEC_TOLERATIONS_0_EFFECT="NoExecute"
EVENT_OBJECT_SPEC_TOLERATIONS_0_KEY="node.kubernetes.io/not-ready"
EVENT_OBJECT_SPEC_TOLERATIONS_0_OPERATOR="Exists"
EVENT_OBJECT_SPEC_TOLERATIONS_0_TOLERATIONSECONDS="300"
EVENT_OBJECT_SPEC_TOLERATIONS_1_EFFECT="NoExecute"
EVENT_OBJECT_SPEC_TOLERATIONS_1_KEY="node.kubernetes.io/unreachable"
EVENT_OBJECT_SPEC_TOLERATIONS_1_OPERATOR="Exists"
EVENT_OBJECT_SPEC_TOLERATIONS_1_TOLERATIONSECONDS="300"
EVENT_OBJECT_SPEC_VOLUMES_0_NAME="default-token-r6ftr"
EVENT_OBJECT_SPEC_VOLUMES_0_SECRET_DEFAULTMODE="420"
EVENT_OBJECT_SPEC_VOLUMES_0_SECRET_SECRETNAME="default-token-r6ftr"
EVENT_OBJECT_STATUS_CONDITIONS_0_LASTPROBETIME=""
EVENT_OBJECT_STATUS_CONDITIONS_0_LASTTRANSITIONTIME="2020-09-02T14:18:46Z"
EVENT_OBJECT_STATUS_CONDITIONS_0_STATUS="True"
EVENT_OBJECT_STATUS_CONDITIONS_0_TYPE="Initialized"
EVENT_OBJECT_STATUS_CONDITIONS_1_LASTPROBETIME=""
EVENT_OBJECT_STATUS_CONDITIONS_1_LASTTRANSITIONTIME="2020-09-02T14:18:53Z"
EVENT_OBJECT_STATUS_CONDITIONS_1_STATUS="True"
EVENT_OBJECT_STATUS_CONDITIONS_1_TYPE="Ready"
EVENT_OBJECT_STATUS_CONDITIONS_2_LASTPROBETIME=""
EVENT_OBJECT_STATUS_CONDITIONS_2_LASTTRANSITIONTIME="2020-09-02T14:18:53Z"
EVENT_OBJECT_STATUS_CONDITIONS_2_STATUS="True"
EVENT_OBJECT_STATUS_CONDITIONS_2_TYPE="ContainersReady"
EVENT_OBJECT_STATUS_CONDITIONS_3_LASTPROBETIME=""
EVENT_OBJECT_STATUS_CONDITIONS_3_LASTTRANSITIONTIME="2020-09-02T14:18:46Z"
EVENT_OBJECT_STATUS_CONDITIONS_3_STATUS="True"
EVENT_OBJECT_STATUS_CONDITIONS_3_TYPE="PodScheduled"
EVENT_OBJECT_STATUS_CONTAINERSTATUSES_0_CONTAINERID="containerd://da0ad052d7e4fc4019a60f916d36279c4edf657aec928335c086e67779e555ac"
EVENT_OBJECT_STATUS_CONTAINERSTATUSES_0_IMAGE="docker.io/library/nginx:latest"
EVENT_OBJECT_STATUS_CONTAINERSTATUSES_0_IMAGEID="docker.io/library/nginx@sha256:b0ad43f7ee5edbc0effbc14645ae7055e21bc1973aee5150745632a24a752661"
EVENT_OBJECT_STATUS_CONTAINERSTATUSES_0_NAME="nginx"
EVENT_OBJECT_STATUS_CONTAINERSTATUSES_0_READY="1"
EVENT_OBJECT_STATUS_CONTAINERSTATUSES_0_RESTARTCOUNT="0"
EVENT_OBJECT_STATUS_CONTAINERSTATUSES_0_STATE_RUNNING_STARTEDAT="2020-09-02T14:18:52Z"
EVENT_OBJECT_STATUS_HOSTIP="172.17.0.2"
EVENT_OBJECT_STATUS_PHASE="Running"
EVENT_OBJECT_STATUS_PODIP="10.244.0.4"
EVENT_OBJECT_STATUS_QOSCLASS="BestEffort"
EVENT_OBJECT_STATUS_STARTTIME="2020-09-02T14:18:46Z"
```

## Road Map

* Provide examples
* Create image and k8s manifests for deploying operators
* Implement e2e tests
* Implement a library for managing CRDs (create, update)

## Inspired by 

* [k8s-operator](https://github.com/side8/k8s-operator)
* [shell-operoator](https://github.com/flant/shell-operator)

(c) 2020 Pablo Chacin.
