# Kubernetes Workloads: Pods, Controllers & Deployment Strategies

Comprehensive practical implementation, lifecycle exploration, controller management, zero-downtime release strategies, and troubleshooting drills based on the SST DevOps & Cloud coursework.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Workload Controller Architecture

Kubernetes orchestrates containerized workloads through a tiered abstraction hierarchy: Deployments manage ReplicaSets, ReplicaSets enforce Pod counts, and Pods wrap container runtimes.

<img src="https://github.com/user-attachments/assets/6465dc5d-8634-4faa-8a6e-2b30ed8fc37f" alt="Workload Controller Architecture" width="100%" />

---

## 1. Task 1: Cluster Health Verification & Baseline Checks

Verify cluster control plane daemons, DNS resolution services, and node readiness before scheduling workloads.

### Commands:
```bash
kubectl cluster-info
kubectl get nodes -o wide
```

### Terminal Output:
```text
Kubernetes control plane is running at https://127.0.0.1:51894
CoreDNS is running at https://127.0.0.1:51894/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION            CONTAINER-RUNTIME
minikube   Ready    control-plane   14m   v1.37.0   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   7.0.12-linuxkit (arm64)   containerd://2.3.4
```

<img src="https://github.com/user-attachments/assets/2ae3b7b1-8046-461c-9e21-30355251f647" alt="Cluster Health Verification" width="100%" />


---

## 2. Task 2: Standard Pod Deployment, Inspection & Teardown

Deploy a standalone Nginx pod manifest specifying all 4 mandatory top-level fields (`apiVersion`, `kind`, `metadata`, `spec`).

### 2.1 Manifest (`pod.yml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
    - name: nginx-container
      image: nginx:alpine
      ports:
        - containerPort: 80
```

### 2.2 Execution & Verification Commands:
```bash
kubectl apply -f pod.yml
kubectl get pods -o wide
kubectl logs nginx-pod
kubectl delete -f pod.yml
```

### Terminal Output:
```text
pod/nginx-pod created

NAME        READY   STATUS              RESTARTS   AGE   IP       NODE       NOMINATED NODE   READINESS GATES
nginx-pod   0/1     ContainerCreating   0          5s    <none>   minikube   <none>           <none>

/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/09/17 18:49:26 [notice] 1#1: using the "epoll" event method
2026/09/17 18:49:26 [notice] 1#1: nginx/1.31.6
2026/09/17 18:49:26 [notice] 1#1: built by gcc 15.2.0 (Alpine 15.2.0)
2026/09/17 18:49:26 [notice] 1#1: OS: Linux 7.0.12-linuxkit
2026/09/17 18:49:26 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2026/09/17 18:49:26 [notice] 1#1: start worker processes
2026/09/17 18:49:26 [notice] 1#1: start worker process 30
2026/09/17 18:49:26 [notice] 1#1: start worker process 31
2026/09/17 18:49:26 [notice] 1#1: start worker process 32
2026/09/17 18:49:26 [notice] 1#1: start worker process 33

pod "nginx-pod" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/b781dd77-5c47-4e51-a613-6adf9c5c0120" alt="Nginx Pod Creation and Initial Status" width="100%" />
<img src="https://github.com/user-attachments/assets/93f1c7e5-6b66-4c8b-bddb-b02ab129f5ff" alt="Nginx Pod Logs and Deletion" width="100%" />


---

## 3. Task 3: Error State Simulation (`ErrImagePull` / `ImagePullBackOff`)

Observe Kubernetes error handling when a pod requests an unresolvable or non-existent container image tag.

### Commands:
```bash
kubectl run error-pod --image=nginx:nonexistent-tag-999 --restart=Never
kubectl get pod error-pod
kubectl describe pod error-pod | grep -A 8 Events:
kubectl delete pod error-pod
```

### Terminal Output:
```text
pod/error-pod created

NAME        READY   STATUS         RESTARTS   AGE
error-pod   0/1     ErrImagePull   0          4s

Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  8s    default-scheduler  Successfully assigned default/error-pod to minikube
  Normal   Pulling    8s    kubelet            spec.containers{error-pod}: Pulling image "nginx:nonexistent-tag-999"
  Warning  Failed     6s    kubelet            spec.containers{error-pod}: Failed to pull image "nginx:nonexistent-tag-999": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:nonexistent-tag-999": failed to resolve reference "docker.io/library/nginx:nonexistent-tag-999": docker.io/library/nginx:nonexistent-tag-999: not found
  Warning  Failed     6s    kubelet            spec.containers{error-pod}: Error: ErrImagePull
  Normal   BackOff    6s    kubelet            spec.containers{error-pod}: Back-off pulling image "nginx:nonexistent-tag-999"
  Warning  Failed     6s    kubelet            spec.containers{error-pod}: Error: ImagePullBackOff

pod "error-pod" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/ba4ffbaa-e9c6-4ef6-82c8-4abe661b664b" alt="Task 3 - ImagePullBackOff Error State Simulation" width="100%" />

---

## 4. Task 4: Transient Pod Lifecycle Stages (`hello.yml`)

Execute a batch execution container (`busybox`) configured with `restartPolicy: Never` to record all lifecycle transitions: `ContainerCreating` -> `Running` -> `Completed` (Phase: `Succeeded`).

### Commands:
```bash
kubectl run hello-pod --image=busybox --restart=Never -- sh -c "echo 'Execution Complete' && sleep 2"
kubectl get pod hello-pod -w
kubectl logs hello-pod
kubectl delete pod hello-pod
```

### Terminal Output:
```text
pod/hello-pod created

NAME        READY   STATUS              RESTARTS   AGE
hello-pod   0/1     ContainerCreating   0          5s
hello-pod   1/1     Running             0          6s
hello-pod   0/1     Completed           0          8s

Execution Complete
pod "hello-pod" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/b16209be-9c9c-448d-bb79-025b43265d89" alt="Transient Pod Lifecycle Transitions" width="100%" />
<img src="https://github.com/user-attachments/assets/03acebb2-5f3b-4a07-bd15-3332ce942a70" alt="Pod Logs and Deletion" width="100%" />



---

## 5. Task 5: Pod Health Probes & Lifecycle Manifests Lab

Validation of advanced pod lifecycle states, health probing mechanisms, and multi-container patterns.

### 5.1 Probes Comparison Matrix

| Probe Type | Evaluation Purpose | Failure Action | Common Use Case |
| :--- | :--- | :--- | :--- |
| **Startup Probe** | Detects application initialization completion | Container is killed and restarted | Slow legacy boot routines (Java/Spring) |
| **Liveness Probe** | Detects deadlocks and internal application freezes | Container is restarted per `restartPolicy` | Catching uncaught exceptions and memory leaks |
| **Readiness Probe** | Determines if container is ready to accept user traffic | Pod IP is removed from Service Endpoints | Warmup caches, database connection verification |

### 5.2 Multi-Container and Sidecar Pod Execution
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
    - name: app-container
      image: busybox
      command: ['sh', '-c', 'while true; do echo "$(date) - Service Healthy" >> /var/log/app.log; sleep 1; done']
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log
    - name: sidecar-logger
      image: busybox
      command: ['sh', '-c', 'tail -n+1 -f /var/log/app.log']
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log
  volumes:
    - name: shared-logs
      emptyDir: {}
```

### Verification Command:
```bash
kubectl apply -f multi-container.yaml
kubectl get pod multi-container-pod
kubectl logs multi-container-pod -c sidecar-logger --tail=3
kubectl delete -f multi-container.yaml
```

### Terminal Output:
```text
pod/multi-container-pod created

NAME                  READY   STATUS    RESTARTS   AGE
multi-container-pod   2/2     Running   0          5s

Thu Sep 17 18:57:41 UTC 2026 - Service Healthy
Thu Sep 17 18:57:42 UTC 2026 - Service Healthy
Thu Sep 17 18:57:43 UTC 2026 - Service Healthy

pod "multi-container-pod" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/996801d3-d36b-4e62-ad4d-d67eb785a9cc" alt="Task 5 - Multi-Container Pod and Sidecar Logging" width="100%" />


---

## 6. Task 6: Controllers Exploration (ReplicaSet & StatefulSet)

### 6.1 ReplicaSet Self-Healing Drill
A ReplicaSet maintains a stable pool of identical pod replicas at any given time.

```bash
kubectl apply -f replicaset.yml
kubectl get rs nginx-rs
kubectl get pods -l app=nginx

# Test self-healing: Terminate an active pod
POD_TARGET=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_TARGET

# Confirm immediate replacement creation
kubectl get pods -l app=nginx
kubectl delete -f replicaset.yml
```

### Terminal Output:
```text
replicaset.apps/nginx-rs created

NAME       DESIRED   CURRENT   READY   AGE
nginx-rs   3         3         3       6s

NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-4sk8z   1/1     Running   0          10s
nginx-rs-gh6px   1/1     Running   0          10s
nginx-rs-n5265   1/1     Running   0          10s

pod "nginx-rs-4sk8z" deleted from default namespace

NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-c5vvb   1/1     Running   0          4s
nginx-rs-gh6px   1/1     Running   0          34s
nginx-rs-n5265   1/1     Running   0          34s

replicaset.apps "nginx-rs" deleted from default namespace
```

### 6.2 StatefulSet Ordinal Naming
Unlike stateless ReplicaSets, StatefulSets provide deterministic, ordered pod hostnames (`mysql-0`, `mysql-1`, `mysql-2`) and persistent storage bindings across reschedules.

<img src="https://github.com/user-attachments/assets/ad40b866-05b2-47b5-9c2f-4bb32481db7b" alt="Task 6 - ReplicaSet Self-Healing Drill" width="100%" />


---

## 7. Task 7: DaemonSet Architecture & Host Agent Deployment

DaemonSets guarantee that all (or eligible) worker nodes execute exactly one copy of a Pod, making them suitable for system monitoring daemons (`node-exporter`, `Prometheus`) and log collectors (`Fluentbit`).

### Command:
```bash
kubectl apply -f deamonset.yml
kubectl get ds node-exporter
kubectl get pods -l app=node-exporter -o wide
kubectl delete -f deamonset.yml
```

### Terminal Output:
```text
daemonset.apps/node-exporter created

NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-exporter   1         1         0       1            0           <none>          6s

NAME                  READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
node-exporter-59w65   1/1     Running   0          11s   10.244.0.11   minikube   <none>           <none>

daemonset.apps "node-exporter" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/79c36fd0-6e9c-4541-8995-ebfe53e6f98d" alt="Task 7 - DaemonSet Host Agent Verification" width="100%" />


---

## 8. Task 8: Deployment Upgrades, Rolling Updates & Rollbacks

Declaratively manage rolling zero-downtime application updates using `maxSurge` and `maxUnavailable` boundaries, with instant rollback support.

### 8.1 Rolling Update Execution
```bash
# 1. Deploy baseline v1
kubectl apply -f deployment-v1.yaml
kubectl rollout status deployment/app-rolling

# 2. Trigger upgrade to v2
kubectl apply -f deployment-v2.yaml
kubectl rollout status deployment/app-rolling

# 3. Inspect deployment revisions
kubectl rollout history deployment/app-rolling

# 4. Execute instant rollback to v1
kubectl rollout undo deployment/app-rolling
kubectl rollout status deployment/app-rolling

# 5. Clean up
kubectl delete -f deployment-v1.yaml
```

### Terminal Output:
```text
deployment.apps/app-rolling created

Waiting for deployment "app-rolling" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-rolling" successfully rolled out

deployment.apps/app-rolling configured

Waiting for deployment "app-rolling" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out

deployment.apps/app-rolling
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

deployment.apps/app-rolling rolled back
deployment "app-rolling" successfully rolled out

deployment.apps "app-rolling" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/f4cda0eb-6166-4aa1-8fd1-d0c60ce2741d" alt="Task 8 - Rolling Update and Rollback Execution" width="100%" />


---

## 9. Task 9: Real-World Troubleshooting Drills

### Drill 1: Broken Image Rollout Diagnosis
When newly surged pods reference an invalid image, rollout stalls automatically while existing pods continue handling user traffic without disruption.

```bash
kubectl create deployment broken-demo --image=nginx:nonexistent-tag-999 --replicas=3
kubectl rollout status deployment/broken-demo --timeout=8s
kubectl delete deployment broken-demo
```

```text
deployment.apps/broken-demo created
Waiting for deployment "broken-demo" rollout to finish: 0 of 3 updated replicas are available...
error: timed out waiting for the condition
deployment.apps "broken-demo" deleted from default namespace
```

### Drill 2: Immutable Label Selector Mismatch
Kubernetes rejects deployment creation if `spec.selector.matchLabels` does not strictly match `spec.template.metadata.labels`.

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: selector-error-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-backend
    spec:
      containers:
        - name: web
          image: nginx:alpine
EOF
```

```text
The Deployment "selector-error-demo" is invalid: spec.template.metadata.labels: Invalid value: {"app":"web-backend"}: `selector` does not match template `labels`
```
*Resolution:* Reconcile the keys in `matchLabels` and `template.metadata.labels` to identical values before reapplying.

<img src="https://github.com/user-attachments/assets/59d9bc5f-099e-4957-a671-2e7c541a4a73" alt="Task 9 - Troubleshooting Drills Stalled Rollout and Selector Mismatch" width="100%" />


---

## 10. Task 10: Theoretical & Architectural Concepts

### 10.1 The 4 Kubernetes Ports Clarified

<img src="https://github.com/user-attachments/assets/ee0dabe0-aa77-4dcf-9da4-7c5eb006d642" alt="The 4 Kubernetes Ports Clarified Architecture" width="100%" />

---

### 10.2 The 4 Primary Deployment Strategies Compared

| Strategy | Downtime | Traffic Behavior | Resource Overhead | Rollback Speed |
| :--- | :---: | :--- | :---: | :---: |
| **RollingUpdate** | Zero | Progressive replacement of old pods | Low (`maxSurge`) | Fast (`kubectl rollout undo`) |
| **Recreate** | Brief Outage | All v1 pods deleted before v2 pods start | None | Moderate |
| **Blue-Green** | Zero | 100% instantaneous cutover via service selector | 2x (Full duplicate stack) | Instant (Selector flip) |
| **Canary** | Zero | Small percentage (e.g. 10%) tested before full rollout | Low (1-2 canary pods) | Fast (Scale canary to 0) |

---

### 10.3 `maxSurge` vs. `maxUnavailable` Math
For a Deployment with `replicas: 4`, `maxSurge: 1`, and `maxUnavailable: 0`:
- **Maximum Allowed Pods During Rollout:** `4 + 1 = 5 pods`
- **Minimum Available Pods During Rollout:** `4 - 0 = 4 pods`
- **Guarantee:** Application maintains 100% capacity throughout the rolling update.

---

### 10.4 Resource Requests vs. Limits & Unit Standards
- **Requests:** Guaranteed minimum CPU/memory allocated by the scheduler to bind the pod to a node.
- **Limits:** Hard ceiling enforced by Linux cgroups. CPU throttles upon limit breach; memory results in immediate container termination (`OOMKilled` - Exit Code 137).
- **Units:** Kubernetes uses IEC binary units (`Mi` = $2^{20}$ bytes, `Gi` = $2^{30}$ bytes), preventing decimal calculation mismatches.

---

## 11. Task 11: Blue-Green Deployment Execution & Selector Cutover

Deploy two complete production environments side by side and flip traffic instantly between them by updating the Service label selector.

### Commands:
```bash
# 1. Deploy both environments simultaneously
kubectl apply -f deployment-blue.yaml
kubectl apply -f deployment-green.yaml

# 2. Route initial traffic to Blue (slot: blue)
kubectl apply -f service-blue.yaml
kubectl describe svc myapp-service | grep -E "Selector|Endpoints"

# 3. Instant Cutover: Flip Service to Green (slot: green)
kubectl apply -f service-green.yaml
kubectl describe svc myapp-service | grep -E "Selector|Endpoints"

# 4. Clean up
kubectl delete -f deployment-blue.yaml -f deployment-green.yaml -f service-green.yaml
```

### Terminal Output:
```text
deployment.apps/myapp-blue created
deployment.apps/myapp-green created
service/myapp-service created

Selector:                 app=myapp,slot=blue
Endpoints:                10.244.0.33:80,10.244.0.35:80,10.244.0.34:80

service/myapp-service configured

Selector:                 app=myapp,slot=green
Endpoints:                10.244.0.37:80,10.244.0.36:80,10.244.0.38:80

deployment.apps "myapp-blue" deleted from default namespace
deployment.apps "myapp-green" deleted from default namespace
service "myapp-service" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/db285694-bb32-475f-ade4-8e9303ca388a" alt="Task 11 - Blue-Green Selector Cutover" width="100%" />


---

## 12. Task 12: Canary Deployment & Pod-Ratio Traffic Splitting

Route live requests across a stable 9-pod baseline (90%) and a canary 1-pod deployment (10%) sharing the same Service selector.

### Commands:
```bash
# 1. Deploy 9 Stable replicas and 1 Canary replica
kubectl apply -f deployment-stable.yaml
kubectl apply -f deployment-canary.yaml
kubectl apply -f service-canary.yaml
sleep 4

# 2. Port-forward service to evaluate traffic distribution
kubectl port-forward svc/canary-service 30030:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 2

# 3. Test traffic splitting across requests
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -s http://localhost:30030
  echo ""
done

# 4. Clean up
kill $PF_PID 2>/dev/null
kubectl delete -f deployment-stable.yaml -f deployment-canary.yaml -f service-canary.yaml
```

### Terminal Output:
```text
deployment.apps/myapp-stable created
deployment.apps/myapp-canary created
service/canary-service created

STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1
STABLE v1

deployment.apps "myapp-stable" deleted from default namespace
deployment.apps "myapp-canary" deleted from default namespace
service "canary-service" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/67643f9f-d8db-42a7-8693-ee4a2e549f9b" alt="Task 12 - Canary Deployment Traffic Distribution" width="100%" />


---

## 13. Task 13: Recreate Deployment & Downtime Outage Demonstration

Demonstrate the behavior of `strategy.type: Recreate`, where all v1 pods are terminated before any v2 pods are created.

### Commands:
```bash
# 1. Deploy initial Recreate deployment
kubectl apply -f deployment-recreate.yaml
kubectl rollout status deployment/app-recreate

# 2. Trigger image update with Recreate strategy
kubectl set image deployment/app-recreate web=nginx:1.25-alpine
kubectl rollout status deployment/app-recreate

# 3. Clean up
kubectl delete -f deployment-recreate.yaml
```

### Terminal Output:
```text
deployment.apps/app-recreate created
deployment "app-recreate" successfully rolled out

deployment.apps/app-recreate image updated
deployment "app-recreate" successfully rolled out

deployment.apps "app-recreate" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/653ce7cd-26ab-49f6-9665-4c4fb957e98a" alt="Task 13 - Recreate Strategy Deployment and Image Rollout" width="100%" />
