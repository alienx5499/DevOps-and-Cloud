# Kubernetes Fundamentals & Cluster Architecture

Documentation and practical verification of local Kubernetes cluster initialization, lifecycle management, and core architectural components based on the SST DevOps & Cloud coursework.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Kubernetes Cluster Architecture

Kubernetes separates cluster management into two distinct planes: the **Control Plane** (responsible for global decision-making, state management, and scheduling) and the **Worker Nodes** (responsible for maintaining running container workloads).

<img src="https://github.com/user-attachments/assets/de8395d9-21d6-472d-9477-90a337920242" alt="Kubernetes Cluster Architecture" width="100%" />

---

## 1. Task 1: Minikube & CLI Installation Verification

Verify that Minikube and the Kubernetes command-line tool (`kubectl`) are installed and available in the system execution path.

### Commands:
```bash
minikube version
kubectl version --client
```

### Terminal Output:
```text
minikube version: v1.39.0
commit: 7a9f6a841470a207de8cf4bafcccee0969d8ba10

Client Version: v1.37.0
Kustomize Version: v5.8.1
```

<img src="https://github.com/user-attachments/assets/b3a17acd-80b9-4b62-9cb2-4d7f12aadd69" alt="Minikube and Kubectl Version Verification" width="100%" />


---

## 2. Task 2: Minikube Cluster Lifecycle Initialization

Initialize a single-node local Kubernetes cluster utilizing the Docker containerized runtime driver.

### Command:
```bash
minikube start --driver=docker
```

### Terminal Output:
```text
😄  minikube v1.39.0 on Darwin 27.0 (arm64)
✨  Using the docker driver based on user configuration
📌  Using Docker Desktop driver with root privileges
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.51 ...
💾  Downloading Kubernetes v1.37.0 preload ...
    > preloaded-images-k8s-v18-v1...:  311.70 MiB / 311.70 MiB  100.00% 1.45 Mi
    > gcr.io/k8s-minikube/kicbase:  470.53 MiB / 470.53 MiB  100.00% 1.54 MiB p
🔥  Creating docker container (CPUs=2, Memory=5874MB) ...
📦  Preparing Kubernetes v1.37.0 on containerd 2.3.4 ...
🔗  Configuring CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

<img src="https://github.com/user-attachments/assets/5e36151c-f65a-4b53-95c4-9a031060f741" alt="Minikube Cluster Start Execution" width="100%" />


---

## 3. Task 3: Cluster Status & Node Health Inspection

Inspect the health of control plane daemons, cluster endpoints, and confirm the worker node status is `Ready`.

### Commands:
```bash
minikube status
kubectl cluster-info
kubectl get nodes -o wide
```

### Terminal Output:
```text
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

Kubernetes control plane is running at https://127.0.0.1:51495
CoreDNS is running at https://127.0.0.1:51495/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION            CONTAINER-RUNTIME
minikube   Ready    control-plane   4m20s   v1.37.0   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   7.0.12-linuxkit (arm64)   containerd://2.3.4
```

<img src="https://github.com/user-attachments/assets/57570161-03f1-41cb-b60c-1703a09b9033" alt="Minikube Status and Node Health" width="100%" />


---

## 4. Task 4: Stopping the Minikube Cluster

Gracefully power down the Minikube cluster container to release system memory and CPU resources.

### Commands:
```bash
minikube stop
minikube status
```

### Terminal Output:
```text
✋  Stopping node "minikube" ...
🛑  Powering off "minikube" via SSH ...
🛑  1 node stopped.

minikube
type: Control Plane
host: Stopped
kubelet: Stopped
apiserver: Stopped
kubeconfig: Configured
```

<img src="https://github.com/user-attachments/assets/30330e6a-6d2e-403e-ae41-c574eefbd1cb" alt="Minikube Graceful Cluster Shutdown" width="100%" />


---

## 5. Task 5: Kubernetes Architecture & Core Component Analysis

A Kubernetes cluster is divided into two primary planes: the **Control Plane (Master Node)** and the **Worker Nodes (Data Plane)**.

### 5.1 Control Plane Components

1. **`kube-apiserver` (The Front Door)**:
   - Exposes the Kubernetes REST API (JSON over HTTP/gRPC).
   - Handles authentication, authorization (RBAC), and admission control validation.
   - Serves as the central communication hub; no other component writes directly to `etcd`.

2. **`etcd` (State Database)**:
   - Consistent, highly-available distributed key-value database.
   - Stores the single source of truth for the entire cluster state, specifications, and metadata.
   - Follows the Raft consensus algorithm for distributed consistency.

3. **`kube-scheduler` (Placement Engine)**:
   - Watches for unscheduled Pods lacking node assignments.
   - Filters candidate nodes based on resource capacity (CPU, memory), affinity/anti-affinity rules, taints, and tolerations, selecting the optimal node.

4. **`kube-controller-manager` (Reconciliation Engine)**:
   - Continuously runs reconciliation loops ensuring **Observed State == Desired State**.
   - Embeds key controllers:
     - *Node Controller*: Handles node heartbeats, health, and eviction timeouts.
     - *ReplicaSet Controller*: Maintains the designated number of active Pod replicas.
     - *Endpoints Controller*: Populates EndpointSlice objects connecting Services to active Pod IPs.

---

### 5.2 Worker Node Components

1. **`kubelet` (Primary Node Agent)**:
   - Runs directly on each worker node as a system daemon.
   - Receives declarative `PodSpec` manifests from `kube-apiserver` and communicates with the container runtime via CRI to instantiate and monitor containers.
   - Reports node and pod health statuses back to the API server.

2. **`kube-proxy` (Network Forwarder)**:
   - Maintains network rules (`iptables` or `IPVS`) on each node.
   - Handles packet forwarding and Layer 4 load balancing for Service virtual IPs across backend Pods.

3. **`Container Runtime (CRI)`**:
   - Software responsible for downloading container images and running container processes.
   - Kubernetes utilizes standardized runtime engines such as **`containerd`** and **`CRI-O`** adhering to the Container Runtime Interface.

4. **`Pod` (Smallest Deployable Unit)**:
   - Encapsulates one or more closely coupled containers.
   - Containers in the same Pod share the same network namespace (`localhost`), IP address, and mounted storage volumes.

---

## Summary: Control Plane vs. Worker Node

| Component | Layer | Primary Responsibility | Critical Protocol / Port |
| :--- | :--- | :--- | :---: |
| **`kube-apiserver`** | Control Plane | Exposes cluster REST API, handles authentication | TCP 6443 |
| **`etcd`** | Control Plane | Key-value state storage and cluster metadata | TCP 2379 / 2380 |
| **`kube-scheduler`** | Control Plane | Evaluates node resources to assign unplaced Pods | TCP 10259 |
| **`kube-controller-manager`** | Control Plane | Runs reconciliation loops to maintain desired state | TCP 10257 |
| **`kubelet`** | Worker Node | Executes PodSpecs, interfaces with container runtime | TCP 10250 |
| **`kube-proxy`** | Worker Node | Program node packet filters (`iptables`/`IPVS`) for Services | TCP 10256 |
| **`containerd`** | Worker Node | Manages container lifecycle, execution, and image pull | UNIX Socket (`containerd.sock`) |
