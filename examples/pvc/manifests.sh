# returns the manifest for a persistent volume
function pv_template(){
cat <<EOF
kind: PersistentVolume
apiVersion: v1
metadata:
  name: "${PVC_NAME}-${NODE_SELECTOR}" 
spec:
  capacity:
    storage: $VOL_SIZE 
  accessModes:
    - ReadWriteOnce 
  storageClassName: local-storage
  local:
    path: "/var/local-volumes/${PVC_NAME}"
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
EOF
}

# returns the manifest for a job
function job_template(){
cat <<EOF
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
        command: ["$JOB_CMD", "$JOB_CMD_ARGS", "/var/local-volumes/$PVC_NAME"]
        volumeMounts:
        - name: local-volumes
          mountPath: "/var"
      volumes:
         - name: local-volumes
           hostPath:
             path: "/var"
             type: Directory
      nodeSelector:
         kubernetes.io/hostname: ${NODE_SELECTOR}
      restartPolicy: Never
EOF
}
