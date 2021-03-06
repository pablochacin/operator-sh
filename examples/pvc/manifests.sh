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
        command: ["$JOB_CMD", "/var/local-volumes/$PVC_NAME"]
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
EOF
}
