# Dynamic Volume Allocation

This example implements an operator that allocates persistent volumes on the node
specified by a persistent volume claim.  

The implementation was inspired by [“Kubernetes Local Persistent Volumes – A Step-by-Step Tutorial](https://vocon-it.com/2018/12/20/kubernetes-local-persistent-volumes)

## PVC added: volume allocation

The `added` hook filters claims not associated with the storage class defined in the STORAGE_CLASS environment variable, which defaults to `local-storage`:

```
VPC_STORAGE_CLASS=$EVENT_OBJECT_SPEC_STORAGECLASSNAME
if [[ "$STORAGE_CLASS" != "$STORAGE_CLASS" ]]; then
   log_info "Ignoring event for storage class $VPC_STORAGE_CLASS"
   exit
fi
```

The hook extracts some information from the claim:

```
# name of the claim (used for binding it)
PVC_NAME=$EVENT_OBJECT_METADATA_NAME
PVC_NAMESPACE=$EVENT_OBJECT_METADATA_NAMESPACE

# node on which the volume must be allocated
NODE_SELECTOR=$EVENT_OBJECT_SPEC_SELECTOR_MATCHLABELS_KUBERNETES_IO_HOSTNAME

# volume size
VOL_SIZE=$EVENT_OBJECT_SPEC_RESOURCES_REQUESTS_STORAGE
```

The operator allocates the persistent volume by running a job on the node specified
by the claim, which creates a directory with the name of the claim:

```
apiVersion: batch/v1
kind: Job
metadata:
  name: ${PVC_NAME}
spec:
  template:
    spec:
      containers:
      - image: busybox
        name: busybox
        command: ["$JOB_CMD", "$CMD_ARGS", "/var/local-volumes/$PVC_NAME"]
        volumeMounts:
        - name: local-volumes
          mountPath: "/var/local-volumes"
      volumes:
         - name: local-volumes
           hostPath:
             path: /mnt/local-volumes
             type: Directory
      nodeSelector:
         kubernetes.io/hostname: ${NODE_SELECTOR}
      restartPolicy: Never
```

Once the volume is allocated, the operator creates a persistent volume and binds it to
the persistent claim:

```
kind: PersistentVolume
apiVersion: v1
metadata:
  name: "${PVC_NAME}-${NODE_SELECTOR}" 
spec:
  capacity:
    storage: $VOL_SIZE 
  accessModes:
    - ReadWriteOnce 
  storageClassName: $STORAGE_CLASSS
  local:
    path: "/mnt/local-volumes"
  claimRef:
    name: ${PVC_NAME}
    namespace: ${PVC_NAMESPACE}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $NODE_SELECTOR 
```

1. The example uses a multi-node kind cluster defined in the `cluster.yaml` configuration
file:

```
$ cat cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
  extraMounts:
  - hostPath: /tmp/kind/volumes/worker1
    containerPath: /mnt/local-volumes
- role: worker
  extraMounts:
  - hostPath: /tmp/kind/volumes/worker2
    containerPath: /mnt/local-volumes
```

The two worker nodes have host volumes mounted in their `/mnt/local-volumes`
directories. This setup facilitates checking if the operator is working
correctly. 

Note: Remember that `kind` create 'nodes' as containers.

Create the cluster with the command:

```
$ kind create cluster --config cluster.yaml
``` 

2. Create a storage class with a dummy provisioner to prevent automatic
volume allocation by other existing provisioners.

```
$ cat storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate 

$ kubectl apply -f storageclass.yaml
storageclass.storage.k8s.io/local-storage created
```

3. In another terminal, start the `operator-sh` to watch the pvc object
and invoke the hooks from the `examples/pvc`

```
$ ./operator.sh -o pvc -h examples/pvc -l /tmp/operator-sh.log -L DEBUG
```

4. In a third terminal, watch the operator's log
```
$ tail -f /tmp/operator-sh.log
```

5. Now in in the first terminal, create a persistent volume claim requesting
a volume in the node `kind-worker-2`

```
$ cat pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: localstorage-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
  selector: 
    matchLabels:
      kubernetes.io/hostname: kind-worker2

$ kubectl apply -f pcv.yaml
persistentvolumeclaim/localstorage-claim created
```

6. The operator's log should show the following messages:
```
2020-10-12 19:46:28 INFO Processing event ADDED for object PersistentVolumeClaim/localstorage-claim
job.batch/localstorage-claim created
persistentvolume/localstorage-claim-kind-worker2 created
2020-10-12 19:46:41 DEBUG No event handler exits for event MODIFIED. Ignoring.
2020-10-12 19:46:42 DEBUG No event handler exits for event MODIFIED. Ignoring.
```

7. The operator should had created a persistent volume in the worker-2 node:

```
$ kubectl get pv
NAME                              CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS    REASON   AGE
localstorage-claim-kind-worker2   1Gi        RWO            Retain           Bound    default/localstorage-claim   local-storage            2m
```

8. The pvc should now be bound to the persistent volume 

```
$ kubectl get pvc
NAME                 STATUS   VOLUME                            CAPACITY   ACCESS MODES   STORAGECLASS    AGE
localstorage-claim   Bound    localstorage-claim-kind-worker2   1Gi        RWO            local-storage   3m
```

9. The pvc operator supports two environment variables to customize the persistent volume creation:
* STORAGE_CLASS: storage class of PCV to watch. PVCs with other storage classes will be ignored. Default to `local-storage`.
* RECLAIM_POLICY: reclaim policy for the PV. Defaults to `Retain`.

## Volume deletion

If RECLAIM_POLICY is defined as "Delete", when a PVC is deleted, the pv and its corresponding backing storage are automatically deleted.
