# Task 1.3: StorageClasses & Dynamic Volume Provisioning

Comprehensive practical guide covering automated on-demand volume lifecycle management, Container Storage Interface (CSI) provisioners, volume expansion, and topology-aware binding modes.

---

## 1. Why Dynamic Provisioning is Essential

In traditional static provisioning, whenever an engineer creates a PersistentVolumeClaim, a cluster administrator must manually create a matching PersistentVolume with the appropriate size, cloud volume ID, and access mode.

This creates severe operational bottlenecks in modern CI/CD and autoscaled production environments:
1. **Administrative Overhead:** Cluster administrators spend excessive time provisioning disks.
2. **Resource Waste:** Static PVs are often over-provisioned or sit idle waiting for claims.
3. **Impeded Automation:** State-dependent applications (databases, message queues, stateful microservices) cannot autoscale or deploy automatically.

### The Solution: StorageClasses
A **StorageClass** provides a blueprint describing the classes of storage offered in the cluster (e.g., standard HDD, fast SSD, multi-AZ replicated). When a developer creates a PVC referencing a StorageClass, Kubernetes automatically invokes the underlying storage provisioner to create the physical volume and bind it seamlessly in real time.

<img width="8192" height="2778" alt="StorageClass Dynamic Provisioning Sequence" src="https://github.com/user-attachments/assets/d5d42079-22fa-43c6-86fb-abfe178f1a1f" />

---

## 2. Key StorageClass Configuration Parameters

| Parameter | Options | Description |
| :--- | :--- | :--- |
| **provisioner** | k8s.io/minikube-hostpath, ebs.csi.aws.com, pd.csi.storage.gke.io | Identifies which volume plugin provisions the underlying storage asset. |
| **volumeBindingMode** | Immediate vs WaitForFirstConsumer | Controls when volume binding and dynamic provisioning should occur. |
| **reclaimPolicy** | Delete (default) or Retain | Determines whether the dynamically provisioned PV is destroyed when the PVC is deleted. |
| **allowVolumeExpansion**| true or false | Enables users to resize their PVC after creation by simply editing spec.resources.requests.storage. |

### Deep Dive: Immediate vs WaitForFirstConsumer
- **Immediate**: As soon as a PVC is created, the storage provisioner allocates a physical disk.
  *Problem in Multi-AZ Clouds:* A volume might be created in AWS us-east-1a, but when the Pod is scheduled, node capacity is only available in us-east-1b. The Pod will become stuck with FailedScheduling because EBS volumes cannot cross availability zones!
- **WaitForFirstConsumer**: Defers volume provisioning and binding until a Pod using the PVC is actually created and scheduled to a node. The storage provisioner creates the disk in the exact Availability Zone where the Pod was scheduled.

---

## 3. Manifest Implementation

### 3.1 StorageClass Manifest (01-storageclass.yaml)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
  labels:
    tier: ssd-fast
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### 3.2 Dynamic PersistentVolumeClaim (02-dynamic-pvc.yaml)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-fast-pvc
  labels:
    tier: ssd-fast
spec:
  storageClassName: fast-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

---

## 4. Verification & Dynamic Provisioning Drill

### 4.1 Apply StorageClass
```bash
# 1. Create the custom StorageClass
kubectl apply -f 01-storageclass.yaml

# 2. Inspect available StorageClasses in the cluster
kubectl get sc
```

Expected Terminal Output:
```text
storageclass.storage.k8s.io/fast-storage created

NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fast-storage         k8s.io/minikube-hostpath   Delete          WaitForFirstConsumer   true                   8s
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate              false                  4d
```

<img src="https://github.com/user-attachments/assets/78001ad0-301c-4da2-a628-f5c0789d8cc8" alt="StorageClass Creation and Configuration Inspection" width="100%" />

### 4.2 Apply Dynamic PVC and Observe Deferred Binding
```bash
# 1. Apply the dynamic claim
kubectl apply -f 02-dynamic-pvc.yaml

# 2. Inspect PVC status
kubectl get pvc dynamic-fast-pvc
```

Expected Terminal Output:
```text
persistentvolumeclaim/dynamic-fast-pvc created

NAME               STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
dynamic-fast-pvc   Pending                                      fast-storage   5s
```

*Note: The PVC remains in Pending state because volumeBindingMode: WaitForFirstConsumer deliberately waits until a Pod references the claim before triggering disk provisioning.*

<img src="https://github.com/user-attachments/assets/b38a9113-48b7-4526-9e6f-18d11dcea340" alt="Dynamic PVC Pending State Under WaitForFirstConsumer" width="100%" />

### 4.3 Trigger Dynamic Provisioning by Running a Consumer Pod
```bash
# 1. Run an ad-hoc consumer pod referencing dynamic-fast-pvc
kubectl run storage-consumer \
  --image=busybox:1.36 \
  --restart=Never \
  --overrides='{
    "spec": {
      "volumes": [{"name": "fast-vol", "persistentVolumeClaim": {"claimName": "dynamic-fast-pvc"}}],
      "containers": [{
        "name": "consumer",
        "image": "busybox:1.36",
        "command": ["sleep", "3600"],
        "volumeMounts": [{"name": "fast-vol", "mountPath": "/mnt/fast-disk"}]
      }]
    }
  }'

# 2. Wait for consumer pod to reach Ready
kubectl wait --for=condition=Ready pod/storage-consumer --timeout=60s

# 3. Check PVC and dynamically generated PV
kubectl get pvc dynamic-fast-pvc
kubectl get pv
```

Expected Terminal Output:
```text
pod/storage-consumer created
pod/storage-consumer condition met

NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
dynamic-fast-pvc   Bound    pvc-3a9d7211-12ef-45ba-91bc-abcdef123456   2Gi        RWO            fast-storage   42s

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS   AGE
pvc-3a9d7211-12ef-45ba-91bc-abcdef123456   2Gi        RWO            Delete           Bound    default/dynamic-fast-pvc   fast-storage   15s
```

<img src="https://github.com/user-attachments/assets/f90ccaed-bf80-400e-a6ab-373f0594357f" alt="Dynamic Volume Provisioning and PV Binding Verification" width="100%" />

**Observation:** Notice that `pvc-3a9d7211-...` was automatically created by the `k8s.io/minikube-hostpath` provisioner with 2Gi capacity and bound directly to `dynamic-fast-pvc` without any manual administrator intervention.
