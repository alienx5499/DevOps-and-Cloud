# Task 2: Troubleshooting Common Kubernetes Issues

Practical breakdown of the most frequent failure states encountered in production Kubernetes clusters. For every scenario, we follow a systematic workflow: identify the symptom, inspect cluster events and logs, locate the root cause, apply the fix, and verify resolution.

---

## 1. Issue Diagnostic Overview

<img width="4890" height="2440" alt="Issue Diagnostic Overview" src="https://github.com/user-attachments/assets/81f986f7-7adb-4665-a66c-85eefbf3c9d3" />

---

## 2. Issue 1: CrashLoopBackOff

### 2.1 Identify the Problem
The pod starts, fails immediately, restarts, and then backs off exponentially:
```bash
kubectl apply -f 01-crashloop.yaml
kubectl get pod crashloop-demo
```

Expected Terminal Output (Before Fix):
```text
NAME              READY   STATUS             RESTARTS      AGE
crashloop-demo    0/1     CrashLoopBackOff   3 (42s ago)   95s
```

<img src="https://github.com/user-attachments/assets/261f0888-82cd-424e-aefc-c9e28b8a8e81" alt="CrashLoopBackOff observed status" width="100%" />

### 2.2 Investigate
Run `kubectl logs` to inspect the process standard error output:
```bash
kubectl logs crashloop-demo
```
If the container already crashed and restarted, inspect the previous run:
```bash
kubectl logs crashloop-demo --previous
```

Terminal Output:
```text
Starting application runtime...
FATAL: Database connection timeout on tcp://db-internal:5432
```

Inspect the container exit code via `describe`:
```bash
kubectl describe pod crashloop-demo | grep -A 4 "Last State"
```

Terminal Output:
```text
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Wed, 30 Sep 2026 11:02:10 +0000
      Finished:     Wed, 30 Sep 2026 11:02:11 +0000
```

### 2.3 Root Cause
The process inside the container exited with non-zero status (Exit Code 1) because a required database dependency was unreachable, causing the container runtime to shut down. Kubelet continually attempted restarts until reaching back-off delay.

### 2.4 Fix
Update the application configuration to handle connection initialization properly or provide the reachable service endpoint:
```yaml
# Fixed pod spec snippet from 01-crashloop.yaml
containers:
  - name: app
    image: busybox:1.36
    command:
      - /bin/sh
      - -c
      - |
        echo "Starting application runtime..."
        echo "Database connection established. Serving traffic."
        sleep 3600
```

### 2.5 Verify the Solution
Delete the failed pod and deploy the corrected definition:
```bash
kubectl delete pod crashloop-demo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: crashloop-demo
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["/bin/sh", "-c", "echo App ready; sleep 3600"]
EOF
kubectl get pod crashloop-demo
```

Expected Terminal Output (After Fix):
```text
NAME              READY   STATUS    RESTARTS   AGE
crashloop-demo    1/1     Running   0          14s
```

<img src="https://github.com/user-attachments/assets/c69636bb-24c1-4419-b061-8cf8c10aebed" alt="CrashLoopBackOff resolved to Running" width="100%" />

---

## 3. Issue 2: ImagePullBackOff & ErrImagePull

### 3.1 Identify the Problem
The pod cannot retrieve its container image from the container registry:
```bash
kubectl apply -f 02-imagepull.yaml
kubectl get pod imagepull-demo
```

Expected Terminal Output (Before Fix):
```text
NAME              READY   STATUS             RESTARTS   AGE
imagepull-demo    0/1     ImagePullBackOff   0          28s
```

<img src="https://github.com/user-attachments/assets/d10a9bd0-5450-43e6-b823-ebf140114e00" alt="ImagePullBackOff observed status" width="100%" />

### 3.2 Investigate
Inspect the event log of the pod:
```bash
kubectl describe pod imagepull-demo
```

Terminal Output:
```text
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  45s                default-scheduler  Successfully assigned default/imagepull-demo to minikube
  Normal   Pulling    18s (x3 over 44s)  kubelet            Pulling image "nginx:this-tag-does-not-exist-v999"
  Warning  Failed     17s (x3 over 43s)  kubelet            Failed to pull image "nginx:this-tag-does-not-exist-v999": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist-v999": not found
  Warning  Failed     17s (x3 over 43s)  kubelet            Error: ErrImagePull
  Normal   BackOff    4s (x2 over 42s)   kubelet            Back-off pulling image "nginx:this-tag-does-not-exist-v999"
  Warning  Failed     4s (x2 over 42s)   kubelet            Error: ImagePullBackOff
```

### 3.3 Root Cause
The image tag `nginx:this-tag-does-not-exist-v999` does not exist on Docker Hub. Other common causes include misspelled repository names or missing private registry pull secrets (`imagePullSecrets`).

### 3.4 Fix
Correct the image tag to a valid image repository:
```bash
kubectl set image pod/imagepull-demo web=nginx:1.27-alpine
# Or re-apply 02-imagepull.yaml with the fixed pod definition
```

### 3.5 Verify the Solution
```bash
kubectl delete pod imagepull-demo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: imagepull-demo
spec:
  containers:
    - name: web
      image: nginx:1.27-alpine
EOF
kubectl get pod imagepull-demo
```

Expected Terminal Output (After Fix):
```text
NAME              READY   STATUS    RESTARTS   AGE
imagepull-demo    1/1     Running   0          12s
```

<img src="https://github.com/user-attachments/assets/07d8fd43-ceaa-4e68-97a8-93e69385dfe7" alt="ImagePullBackOff resolved to Running" width="100%" />

---

## 4. Issue 3: Pending Pods

### 4.1 Identify the Problem
The pod remains in `Pending` state indefinitely without ever reaching `ContainerCreating`:
```bash
kubectl apply -f 03-pending.yaml
kubectl get pod pending-demo
```

Expected Terminal Output (Before Fix):
```text
NAME           READY   STATUS    RESTARTS   AGE
pending-demo   0/1     Pending   0          45s
```

<img src="https://github.com/user-attachments/assets/54932cc5-fa7c-4954-ba9d-d43cc84a0797" alt="Pending Pod observed status" width="100%" />

### 4.2 Investigate
Run `kubectl describe` to check scheduler events:
```bash
kubectl describe pod pending-demo
```

Terminal Output:
```text
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  52s   default-scheduler  0/1 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }, 1 node(s) didn't match Pod's node selector, 1 Insufficient cpu, 1 Insufficient memory.
```

### 4.3 Root Cause
Two constraints prevented scheduling:
1. `nodeSelector` requested a label (`disktype: non-existent-hardware-nvme`) that no node in the cluster possesses.
2. `resources.requests` specified 500 CPU cores and 500Gi memory, far exceeding total node capacity.

### 4.4 Fix
Remove the invalid `nodeSelector` and adjust resource requests to fit within the cluster profile:
```yaml
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
```

### 4.5 Verify the Solution
```bash
kubectl delete pod pending-demo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pending-demo
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
EOF
kubectl get pod pending-demo
```

Expected Terminal Output (After Fix):
```text
NAME           READY   STATUS    RESTARTS   AGE
pending-demo   1/1     Running   0          8s
```

<img src="https://github.com/user-attachments/assets/89e37bfc-fd88-4e9c-b69d-cc806174f5cd" alt="Pending Pod resolved to Running" width="100%" />

---

## 5. Issue 4: ContainerCreating (Configuration / Volume Blockers)

### 5.1 Identify the Problem
The pod is scheduled, but stays stuck in `ContainerCreating`:
```bash
kubectl apply -f 04-containercreating.yaml
kubectl get pod containercreating-demo
```

Expected Terminal Output (Before Fix):
```text
NAME                     READY   STATUS              RESTARTS   AGE
containercreating-demo   0/1     ContainerCreating   0          40s
```

<img src="https://github.com/user-attachments/assets/e5947890-4043-4b2b-8e66-ca87754b301e" alt="ContainerCreating observed status" width="100%" />

### 5.2 Investigate
Inspect the event trail:
```bash
kubectl describe pod containercreating-demo
```

Terminal Output:
```text
Events:
  Type     Reason       Age               From               Message
  ----     ------       ----              ----               -------
  Normal   Scheduled    50s               default-scheduler  Successfully assigned default/containercreating-demo to minikube
  Warning  FailedMount  10s (x8 over 50s) kubelet            MountVolume.SetUp failed for volume "config-volume" : configmap "non-existent-config" not found
```

### 5.3 Root Cause
The container runtime cannot initialize environment variables or mounts because the referenced `ConfigMap` (`non-existent-config`) does not exist in the namespace.

### 5.4 Fix
Create the missing ConfigMap or update the pod to point to an existing ConfigMap:
```bash
kubectl create configmap non-existent-config --from-literal=APP_ENV=production
```

### 5.5 Verify the Solution
```bash
kubectl get pod containercreating-demo
```

Expected Terminal Output (After Fix):
```text
NAME                     READY   STATUS    RESTARTS   AGE
containercreating-demo   1/1     Running   0          65s
```

<img src="https://github.com/user-attachments/assets/92df5723-32c9-4e71-b73c-ae0fd4e7adb8" alt="ContainerCreating resolved to Running" width="100%" />

---

## 6. Issue 5: Service Connectivity & DNS Troubleshooting

### 6.1 Identify the Problem
Client pods receive HTTP 503 errors or connection timeouts when trying to reach `backend-service-broken`:
```bash
kubectl apply -f 05-service-dns.yaml
kubectl exec dns-client-pod -- wget -qO- --timeout=3 http://backend-service-broken
```

Expected Terminal Output (Before Fix):
```text
wget: download timed out
```

<img src="https://github.com/user-attachments/assets/0288cf1c-ea39-4602-8b86-8348819d2fa4" alt="Service connectivity failure observed" width="100%" />

### 6.2 Investigate
Inspect the Service endpoints:
```bash
kubectl get endpoints backend-service-broken
```

Terminal Output:
```text
NAME                     ENDPOINTS   AGE
backend-service-broken   <none>      25s
```

Check the Service selector against the actual Pod labels:
```bash
# Check service selector
kubectl get service backend-service-broken -o jsonpath='{.spec.selector}' && echo ""

# Check deployment template labels
kubectl get pods --show-labels -l app=backend-api
```

Terminal Output:
```text
{"app":"backend-apii"}
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
backend-api-7b89df5c4b-4q2lm   1/1     Running   0          45s   app=backend-api,pod-template-hash=7b89df5c4b
backend-api-7b89df5c4b-9z8jx   1/1     Running   0          45s   app=backend-api,pod-template-hash=7b89df5c4b
```

### 6.3 Root Cause
The Service selector specifies `app: backend-apii` (contains a typo). It does not match the actual pod labels (`app: backend-api`), so the Service controller populates zero backend IP endpoints.

### 6.4 Fix
Update the Service selector to match the pod labels:
```bash
kubectl set selector service backend-service-broken "app=backend-api"
```

### 6.5 Verify the Solution
Verify endpoints are now populated:
```bash
kubectl get endpoints backend-service-broken
```

Expected Terminal Output:
```text
NAME                     ENDPOINTS                         AGE
backend-service-broken   10.244.0.8:80,10.244.0.9:80       2m
```

Test DNS resolution and HTTP response from the client pod:
```bash
# Test CoreDNS resolution
kubectl exec dns-client-pod -- nslookup backend-service-broken

# Test HTTP request through Service ClusterIP
kubectl exec dns-client-pod -- wget -qO- http://backend-service-broken | grep "<title>"
```

Expected Terminal Output:
```text
Server:    10.96.0.10
Address:   10.96.0.10:53

Name:      backend-service-broken.default.svc.cluster.local
Address:   10.104.182.45

<title>Welcome to nginx!</title>
```

<img src="https://github.com/user-attachments/assets/a30a61b8-f569-4c70-adcf-788432ba9c79" alt="Service endpoints and DNS resolution verified" width="100%" />

---

## 7. Summary Troubleshooting Matrix

| Issue | Typical Status | Primary Inspection Command | Common Root Causes | Immediate Solution |
| :--- | :--- | :--- | :--- | :--- |
| **App Crash** | `CrashLoopBackOff` | `kubectl logs <pod> --previous` | Uncaught exception, missing env var, DB down | Fix app code or inject required config |
| **Bad Image** | `ImagePullBackOff` | `kubectl describe pod <pod>` | Tag typo, private registry missing secret | Fix image tag or add imagePullSecret |
| **Capacity** | `Pending` | `kubectl describe pod <pod>` | NodeSelector mismatch, CPU/RAM request too high | Lower resource requests, fix node labels |
| **Config** | `ContainerCreating` | `kubectl describe pod <pod>` | Referenced ConfigMap, Secret, or PVC missing | Create missing Kubernetes object |
| **Routing** | `Endpoints: <none>` | `kubectl describe service <svc>` | Selector typo, port vs targetPort mismatch | Align selector with pod labels |
| **DNS** | `nslookup timeout` | `kubectl logs -n kube-system -l k8s-app=kube-dns` | CoreDNS pod crashed, UDP 53 blocked | Restart CoreDNS, check network policy |
