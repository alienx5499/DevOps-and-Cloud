# Task 1: Essential Kubernetes Troubleshooting Commands

Hands-on reference for the foundational CLI commands used to observe cluster state, inspect metadata, view application output, execute remote shell sessions, and monitor resource usage.

---

## 1. The Core Inspection Flow

When an issue occurs, avoid randomly restarting workloads. Follow a structured inspection sequence:

<img width="5640" height="725" alt="The Core Inspection Flow" src="https://github.com/user-attachments/assets/866f1b39-59ce-4cac-801b-9f55e0f9bf84" />

---

## 2. Command Reference & Hands-on Verification

Deploy the demonstration pod first:
```bash
kubectl apply -f pod.yaml
```

---

### 2.1 kubectl get

Lists resources in the current namespace. It answers the question: "What resources exist and what is their status?"

```bash
kubectl get pods
```

Expected Terminal Output:
```text
NAME               READY   STATUS    RESTARTS   AGE
demo-inspect-pod   1/1     Running   0          18s
```

<img src="https://github.com/user-attachments/assets/99d70c42-4272-405f-ad9c-99344450ef0e" alt="kubectl get pods output" width="100%" />

---

### 2.2 kubectl get -o wide

Expands output columns to include IP address, node assignment, nominated node, and readiness gates. It answers: "Which physical or virtual worker node hosts this pod, and what IP was assigned?"

```bash
kubectl get pods -o wide
```

Expected Terminal Output:
```text
NAME               READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
demo-inspect-pod   1/1     Running   0          32s   10.244.0.5   minikube   <none>           <none>
```

<img src="https://github.com/user-attachments/assets/11329cbe-1430-43f9-8ad2-66cde2e297aa" alt="kubectl get pods wide output" width="100%" />

---

### 2.3 kubectl describe

Retrieves the complete state representation of a resource directly from the Kubernetes API server, combining metadata, container specs, current condition flags, and recent cluster events.

```bash
kubectl describe pod demo-inspect-pod
```

Expected Terminal Output:
```text
Name:             demo-inspect-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Wed, 30 Sep 2026 10:45:10 +0000
Labels:           app=demo-app
                  env=staging
                  tier=frontend
Status:           Running
IP:               10.244.0.5
Containers:
  web:
    Container ID:   containerd://e8b934b1...
    Image:          nginx:1.27-alpine
    Image ID:       docker.io/library/nginx@sha256:...
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 30 Sep 2026 10:45:12 +0000
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:        50m
      memory:     32Mi
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  45s   default-scheduler  Successfully assigned default/demo-inspect-pod to minikube
  Normal  Pulling    44s   kubelet            Pulling image "nginx:1.27-alpine"
  Normal  Pulled     42s   kubelet            Successfully pulled image "nginx:1.27-alpine"
  Normal  Created    42s   kubelet            Created container: web
  Normal  Started    41s   kubelet            Started container: web
```

<img src="https://github.com/user-attachments/assets/44407f74-7360-4e85-93ec-56d809c90832" alt="kubectl describe pod output" width="100%" />

---

### 2.4 kubectl logs

Streams the standard output and standard error streams from the target container runtime.

```bash
# View current logs
kubectl logs demo-inspect-pod

# Stream logs in real time
kubectl logs -f demo-inspect-pod

# View logs from a previous crashed container instance
kubectl logs demo-inspect-pod --previous
```

Expected Terminal Output:
```text
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/09/30 10:45:12 [notice] 1#1: using the "epoll" event method
2026/09/30 10:45:12 [notice] 1#1: nginx/1.27.0
2026/09/30 10:45:12 [notice] 1#1: OS: Linux 6.6.31-linuxkit
2026/09/30 10:45:12 [notice] 1#1: start worker processes
```

<img src="https://github.com/user-attachments/assets/85c123fe-c733-43b8-8ac1-163c4babe8ae" alt="kubectl logs output" width="100%" />

---

### 2.5 kubectl exec

Opens an interactive shell or executes a single command inside a running container. Used to test local connectivity, check configuration files, or verify DNS.

```bash
# Run a single command directly
kubectl exec demo-inspect-pod -- nginx -v

# Run curl against localhost inside the pod
kubectl exec demo-inspect-pod -- wget -qO- http://localhost:80 | grep "<title>"

# Open an interactive terminal
kubectl exec -it demo-inspect-pod -- /bin/sh
```

Expected Terminal Output:
```text
nginx version: nginx/1.27.0
<title>Welcome to nginx!</title>
```

<img src="https://github.com/user-attachments/assets/6da2c450-ceee-471d-b1a8-d5f02d7bd2c4" alt="kubectl exec output" width="100%" />

---

### 2.6 kubectl get events

Displays cluster events recorded by the Kubernetes API server within the past hour. Events reveal scheduler decisions, image pull failures, probe failures, and node pressures.

```bash
# View events sorted by timestamp
kubectl get events --sort-by='.metadata.creationTimestamp'

# Filter events related to a specific pod
kubectl get events --field-selector involvedObject.name=demo-inspect-pod
```

Expected Terminal Output:
```text
LAST SEEN   TYPE     REASON      OBJECT                 MESSAGE
2m          Normal   Scheduled   pod/demo-inspect-pod   Successfully assigned default/demo-inspect-pod to minikube
2m          Normal   Pulling     pod/demo-inspect-pod   Pulling image "nginx:1.27-alpine"
2m          Normal   Pulled      pod/demo-inspect-pod   Successfully pulled image "nginx:1.27-alpine"
2m          Normal   Created     pod/demo-inspect-pod   Created container: web
2m          Normal   Started     pod/demo-inspect-pod   Started container: web
```

<img src="https://github.com/user-attachments/assets/0d482733-0650-4313-a367-a42e5a816956" alt="kubectl get events output" width="100%" />

---

### 2.7 kubectl explain

Built-in documentation tool that parses the OpenAPI schema of the cluster API server. It provides exact field names, types, and descriptions for any Kubernetes resource.

```bash
# Inspect the top-level specification fields of a Pod
kubectl explain pod.spec

# Inspect container resource requirements
kubectl explain pod.spec.containers.resources
```

Expected Terminal Output:
```text
KIND:       Pod
VERSION:    v1

FIELD: resources <ResourceRequirements>

DESCRIPTION:
    Compute Resources required by this container. Cannot be updated. More
    info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

FIELDS:
    claims   <[]ResourceClaim>
    limits   <map[string]Quantity>
    requests <map[string]Quantity>
```

<img src="https://github.com/user-attachments/assets/993292cc-49d1-41bf-af6f-bff4e6b2c2d9" alt="kubectl explain output" width="100%" />

---

### 2.8 kubectl top

Queries the Metrics Server to return real-time CPU (in millicores) and Memory (in mebibytes) utilization for nodes and pods.

```bash
# View pod resource consumption
kubectl top pod demo-inspect-pod

# View node resource consumption
kubectl top nodes
```

Expected Terminal Output:
```text
NAME               CPU(cores)   MEMORY(bytes)
demo-inspect-pod   1m           5Mi

NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   185m         9%     1410Mi          18%
```

<img src="https://github.com/user-attachments/assets/dd29dfed-ef6f-4efe-b17f-5fc90e921f2e" alt="kubectl top output" width="100%" />

---

## 3. Summary of Commands

| Command | Primary Use Case | First Question It Answers |
| :--- | :--- | :--- |
| `kubectl get` | High-level status overview | Is the pod Running, Pending, or in Error? |
| `kubectl get -o wide` | Node and IP mapping | Which node hosts the pod and what is its IP? |
| `kubectl describe` | State details and event trail | Why did the container fail or restart? |
| `kubectl logs` | Application stdout/stderr | What did the application log before dying? |
| `kubectl exec` | In-container testing | Can the container reach its dependencies? |
| `kubectl get events` | Cluster event timeline | Did the scheduler or kubelet report failures? |
| `kubectl explain` | API schema reference | What is the correct YAML field syntax? |
| `kubectl top` | Real-time resource metrics | Is the pod CPU throttled or nearing OOM? |
