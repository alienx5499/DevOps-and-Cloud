# Task 1.1: Kubernetes Node-Local Volumes - emptyDir & hostPath

Comprehensive practical guide covering Kubernetes Pod-level volume abstractions, ephemeral scratch space sharing between multi-container pods (emptyDir), and node-level filesystem mounting (hostPath).

---

## 1. Overview of Node-Local Volumes

Containers in Kubernetes are ephemeral by default. When a container restarts, all modified or uncommitted files within its root filesystem layer are lost. Kubernetes Volumes provide Pod-level storage abstractions that outlive individual container crashes.

Node-local volumes are directly tied to the node where the Pod is scheduled:

| Volume Type | Lifecycle Scope | Backing Media | Typical Use Cases |
| :--- | :--- | :--- | :--- |
| **emptyDir** | Bound strictly to Pod lifecycle | Node disk or RAM (tmpfs) | Temporary scratchpad, multi-container data pipelining, sorting buffers |
| **hostPath** | Bound to Node filesystem | Node host filesystem (/var/log, /etc) | System DaemonSets, node log collectors (Fluentd/Promtail), cAdvisor monitoring |

---

## 2. emptyDir: Multi-Container Shared Scratchpad

An emptyDir volume is created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node. All containers in the Pod can read and write the same files in the emptyDir volume, though each container can mount the volume at the same or different paths.

### 2.1 Architecture Diagram

<img width="4623" height="1275" alt="emptyDir Architecture" src="https://github.com/user-attachments/assets/09d037f5-a1d7-4937-b32c-68428ce8cd4c" />

### 2.2 Manifest (01-emptydir-pod.yaml)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo-pod
  labels:
    app: storage-demo
    storage-type: emptydir
spec:
  containers:
    - name: writer-container
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - >
          while true; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Writer container health beat" >> /shared-data/status.log;
            sleep 5;
          done
      volumeMounts:
        - name: scratch-volume
          mountPath: /shared-data

    - name: reader-container
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - >
          echo "Reader started. Monitoring shared volume...";
          tail -f /shared-data/status.log;
      volumeMounts:
        - name: scratch-volume
          mountPath: /shared-data
          readOnly: true

  volumes:
    - name: scratch-volume
      emptyDir:
        sizeLimit: 100Mi
```

### 2.3 Verification Commands & Output
```bash
# 1. Deploy the emptyDir pod
kubectl apply -f 01-emptydir-pod.yaml

# 2. Verify Pod running status
kubectl get pod emptydir-demo-pod

# 3. Stream reader container logs to observe data written by writer container
kubectl logs emptydir-demo-pod -c reader-container
```

Expected Terminal Output:
```text
pod/emptydir-demo-pod created

NAME                READY   STATUS    RESTARTS   AGE
emptydir-demo-pod   2/2     Running   0          12s

Reader started. Monitoring shared volume...
2026-09-29 10:40:02 - Writer container health beat
2026-09-29 10:40:07 - Writer container health beat
2026-09-29 10:40:12 - Writer container health beat
```

<img src="https://github.com/user-attachments/assets/20089224-8dbc-4d56-b2d7-0ad1c00719c2" alt="emptyDir Pod Creation and Multi-Container Log Streaming" width="100%" />

---

## 3. hostPath: Node Filesystem Mounting

A hostPath volume mounts a file or directory from the host node filesystem into your Pod. This allows privileged system agents or monitoring daemons to access host kernel logs, socket files, or hardware metrics.

### 3.1 Supported hostPath Types

| Type | Description | Behavior if Path Does Not Exist |
| :--- | :--- | :--- |
| "" (Empty string) | Unchecked hostPath mount | Preserved as-is |
| DirectoryOrCreate | Directory on host node | Created with 0755 permissions if missing |
| Directory | Existing directory on host node | Pod fails to schedule with MountVolume.SetUp failed |
| FileOrCreate | Single file on host node | Created with 0644 permissions if missing |
| File | Existing file on host node | Pod fails if missing |
| Socket | UNIX socket on host node | Required for daemon communication (Docker or CRI socket) |

### 3.2 Architecture Diagram

<img width="3236" height="1065" alt="hostPath Architecture" src="https://github.com/user-attachments/assets/2cdfa618-75a3-4f1e-9706-988bfb37b7a4" />

### 3.3 Manifest (02-hostpath-pod.yaml)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo-pod
  labels:
    app: storage-demo
    storage-type: hostpath
spec:
  containers:
    - name: hostpath-agent
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - >
          echo "HostPath agent active. Writing system telemetry...";
          echo "Pod started on node at $(date)" >> /node-logs/k8s-agent-startup.log;
          tail -f /dev/null;
      volumeMounts:
        - name: node-log-volume
          mountPath: /node-logs

  volumes:
    - name: node-log-volume
      hostPath:
        path: /var/log
        type: DirectoryOrCreate
```

### 3.4 Verification Commands & Output
```bash
# 1. Deploy hostPath pod
kubectl apply -f 02-hostpath-pod.yaml

# 2. Inspect host mount in the container
kubectl exec hostpath-demo-pod -- ls -lah /node-logs

# 3. Read startup log written to host filesystem
kubectl exec hostpath-demo-pod -- cat /node-logs/k8s-agent-startup.log
```

Expected Terminal Output:
```text
pod/hostpath-demo-pod created

total 24K
drwxr-xr-x    3 root     root        4.0K Sep 29 10:42 .
drwxr-xr-x    1 root     root        4.0K Sep 29 10:42 ..
-rw-r--r--    1 root     root          52 Sep 29 10:42 k8s-agent-startup.log
drwxr-xr-x    2 root     root        4.0K Sep 29 10:00 pods

Pod started on node at Tue Sep 29 10:42:15 UTC 2026
```

<img src="https://github.com/user-attachments/assets/8a40f42b-1e52-48d1-82e2-3f2a0e97bb4f" alt="hostPath Volume Mount and Host Log Inspection" width="100%" />

---

## 4. Key Takeaways & Security Best Practices

1. **emptyDir is NOT persistent:** When a Pod is deleted, evicted, or rescheduled to another node, the emptyDir volume is completely erased.
2. **hostPath breaks cloud portability:** Pods using hostPath are tightly coupled to the specific node where they run. If the Pod is rescheduled to another node in a multi-node cluster, previous data will not be available.
3. **Security Caution with hostPath:** Giving containers read or write access to `/` or `/var/run` on the host node introduces serious security risks, as container breakout vulnerabilities could allow root compromise of the host OS.
