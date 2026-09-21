# Task 1.2: Persistent Volumes (PV) & Persistent Volume Claims (PVC)

Comprehensive guide covering decoupled cluster storage architecture, static storage provisioning, claim binding mechanics, access modes, and data retention guarantees across Pod lifecycles.

---

## 1. Architectural Philosophy: Decoupling Storage from Pods

In production Kubernetes clusters, storage administration is strictly separated from application deployment:
- **Cluster Administrators** provision storage infrastructure (SAN, NFS, AWS EBS, GCE Persistent Disks, Ceph) and expose them as **PersistentVolumes (PV)**.
- **Application Developers** request storage capacity, access modes, and quality-of-service through **PersistentVolumeClaims (PVC)** without needing to know physical disk paths, credentials, or cloud volume IDs.

<img width="5949" height="1180" alt="PersistentVolume and PersistentVolumeClaim Architecture" src="https://github.com/user-attachments/assets/78a889ce-325c-4187-8eef-c7e1b9040742" />


---

## 2. The 4 Phases of the PV and PVC Lifecycle

| Phase | Description |
| :--- | :--- |
| **1. Provisioning** | Creating the storage volume. Either **Static** (admin manually creates PVs beforehand) or **Dynamic** (storage plugin creates PV on-demand when a PVC requests a StorageClass). |
| **2. Binding** | The control plane matches a PVC to an appropriate PV based on capacity, accessModes, and storageClassName. The match creates an exclusive 1-to-1 binding between the PV and PVC. |
| **3. Using** | Pods specify persistentVolumeClaim.claimName under spec.volumes. The cluster inspects the claim, locates the bound PV, mounts the backing volume into the node, and mounts it into the container. |
| **4. Reclaiming** | Defines what happens to the underlying storage when the PVC is deleted. |

### Reclaim Policies (persistentVolumeReclaimPolicy)
- **Retain**: The PV remains intact, preserving all data. The status changes to Released. No other claim can bind to it until an admin manually scrubs the volume.
- **Delete**: The PV and the backing external storage asset (such as AWS EBS volume or GCE disk) are automatically deleted.
- **Recycle**: Basic scrubbing (rm -rf /thevolume/*) making the volume available to new claims.

---

## 3. Storage Access Modes

| Access Mode | CLI Abbr | Description |
| :--- | :--- | :--- |
| **ReadWriteOnce** | RWO | The volume can be mounted as read-write by a single cluster node. |
| **ReadOnlyMany** | ROX | The volume can be mounted read-only by multiple cluster nodes concurrently. |
| **ReadWriteMany** | RWX | The volume can be mounted read-write by multiple cluster nodes concurrently (requires NFS, CephFS, AWS EFS, or Azure Files). |
| **ReadWriteOncePod**| RWOP| The volume can be mounted as read-write by exactly one single Pod in the entire cluster. |

---

## 4. Manifest Implementation

### 4.1 PersistentVolume (01-pv.yaml)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-data-pv
  labels:
    type: local
    environment: production
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/k8s-static-data
    type: DirectoryOrCreate
```

### 4.2 PersistentVolumeClaim (02-pvc.yaml)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-data-pvc
  labels:
    app: persistent-demo
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### 4.3 Pod Consuming PVC (03-pod-pvc.yaml)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: persistent-storage-pod
  labels:
    app: persistent-demo
spec:
  containers:
    - name: data-app
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
          name: http
      volumeMounts:
        - name: persistent-storage
          mountPath: /usr/share/nginx/html
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: static-data-pvc
```

---

## 5. Step-by-Step Verification & Persistence Drill

### 5.1 Create PV and PVC
```bash
# 1. Create the PersistentVolume
kubectl apply -f 01-pv.yaml

# 2. Verify PV is in 'Available' state
kubectl get pv static-data-pv

# 3. Create the PersistentVolumeClaim
kubectl apply -f 02-pvc.yaml

# 4. Verify PV and PVC transitioned to 'Bound' state
kubectl get pv static-data-pv
kubectl get pvc static-data-pvc
```

Expected Terminal Output:
```text
persistentvolume/static-data-pv created
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   AGE
static-data-pv   1Gi        RWO            Retain           Available           manual         4s

persistentvolumeclaim/static-data-pvc created
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS   AGE
static-data-pv   1Gi        RWO            Retain           Bound    default/static-data-pvc   manual         12s

NAME              STATUS   VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   AGE
static-data-pvc   Bound    static-data-pv   1Gi        RWO            manual         3s
```

<img src="https://github.com/user-attachments/assets/a71c5df7-e99b-4f55-8130-5747c271061e" alt="PV and PVC Creation and Bound Status Inspection" width="100%" />

### 5.2 Deploy Pod and Write Persistent Data
```bash
# 1. Deploy the Pod
kubectl apply -f 03-pod-pvc.yaml
kubectl wait --for=condition=Ready pod/persistent-storage-pod --timeout=60s

# 2. Write an HTML file to the persistent volume mount
kubectl exec persistent-storage-pod -- sh -c 'echo "<h1>Persistent Storage Test: Prabal Patra (24BCS10031)</h1>" > /usr/share/nginx/html/index.html'

# 3. Verify content served locally via curl
kubectl exec persistent-storage-pod -- curl -s http://localhost/index.html
```

Expected Terminal Output:
```text
pod/persistent-storage-pod created
pod/persistent-storage-pod condition met

<h1>Persistent Storage Test: Prabal Patra (24BCS10031)</h1>
```

<img src="https://github.com/user-attachments/assets/c4543cb8-796e-4fff-b060-45de328ef8ce" alt="Pod Mounting PVC and Writing Persistent File" width="100%" />

### 5.3 Pod Deletion and Data Survival Drill
```bash
# 1. Delete the Pod completely
kubectl delete pod persistent-storage-pod

# 2. Verify the PVC and PV remain intact and Bound
kubectl get pvc static-data-pvc
kubectl get pv static-data-pv

# 3. Launch a new Pod binding to the exact same PVC
kubectl apply -f 03-pod-pvc.yaml
kubectl wait --for=condition=Ready pod/persistent-storage-pod --timeout=60s

# 4. Read the file again to verify absolute data preservation
kubectl exec persistent-storage-pod -- curl -s http://localhost/index.html
```

Expected Terminal Output:
```text
pod "persistent-storage-pod" deleted

NAME              STATUS   VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   AGE
static-data-pvc   Bound    static-data-pv   1Gi        RWO            manual         3m

NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS   AGE
static-data-pv   1Gi        RWO            Retain           Bound    default/static-data-pvc   manual         3m

pod/persistent-storage-pod created
pod/persistent-storage-pod condition met

<h1>Persistent Storage Test: Prabal Patra (24BCS10031)</h1>
```

<img src="https://github.com/user-attachments/assets/494cab99-fa66-4823-b51d-ddd08befca10" alt="Pod Deletion and Data Retention Verification" width="100%" />

**Conclusion:** Even though the Pod was completely destroyed and rescheduled, the data remained safe on the underlying PersistentVolume.
