# Task 3: Container Health Checks (Startup, Readiness & Liveness Probes)

Practical implementation of Kubernetes health checking mechanisms. Covers how to prevent premature restarts on slow boots, gate network traffic until an app is actually ready, and automatically recover from hung processes.

---

## 1. Overview of the three probe types

Kubernetes provides three distinct probe mechanisms:

<img width="3720" height="4805" alt="Container Health Probes Decision Flow" src="https://github.com/user-attachments/assets/037046ad-cb98-4a4d-af52-7e6e5e52b82f" />

| Probe | Problem it solves | Action taken on failure |
| :--- | :--- | :--- |
| **startupProbe** | Application takes 30 to 90 seconds to initialize database connections or compile caches | Kubelet restarts container. Keeps other probes disabled until it succeeds |
| **readinessProbe** | Application is temporarily overloaded or warming up and should not get user requests yet | Removes Pod IP from Service Endpoints. Does not restart the container |
| **livenessProbe** | Application process is stuck in a deadlock or thread exhaustion and cannot recover on its own | Restarts the container via container runtime |

---

## 2. Common configuration parameters

- `initialDelaySeconds`: Number of seconds to wait after container start before sending the first probe.
- `periodSeconds`: How frequently (in seconds) to perform the probe check.
- `timeoutSeconds`: Number of seconds after which the probe times out (defaults to 1s).
- `failureThreshold`: Number of consecutive failures needed before taking action.
- `successThreshold`: Number of consecutive successful probes required after a failure (defaults to 1).

---

## 3. Manifests

### 3.1 Startup probe (01-startup-probe.yaml)
Protects applications with long boot times. If this probe takes 25 seconds, it will not be killed prematurely:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-probe-pod
  labels:
    app: probe-demo
    probe-type: startup
spec:
  containers:
    - name: slow-init-app
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - >
          echo "Simulating 20-second startup initialization...";
          sleep 20;
          touch /tmp/started;
          echo "Application started. Serving requests...";
          while true; do sleep 5; done
      startupProbe:
        exec:
          command:
            - cat
            - /tmp/started
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 10
        timeoutSeconds: 2
      livenessProbe:
        exec:
          command:
            - cat
            - /tmp/started
        periodSeconds: 10
        failureThreshold: 3
```

### 3.2 Readiness probe (02-readiness-probe.yaml)
Ensures NGINX only receives network traffic once port 80 responds with HTTP 200:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-probe-pod
  labels:
    app: probe-demo
    probe-type: readiness
spec:
  containers:
    - name: web-service
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
          name: http
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 3
        timeoutSeconds: 2
```

### 3.3 Liveness probe (03-liveness-probe.yaml)
Demonstrates self-healing. The pod creates `/tmp/healthy`, sleeps 25 seconds, and then removes it to simulate a deadlocked state:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-probe-pod
  labels:
    app: probe-demo
    probe-type: liveness
spec:
  containers:
    - name: resilient-app
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - >
          touch /tmp/healthy;
          echo "Container started as healthy. Will simulate failure after 25s...";
          sleep 25;
          rm -rf /tmp/healthy;
          echo "Simulated deadlock or failure! File removed.";
          while true; do sleep 5; done
      livenessProbe:
        exec:
          command:
            - cat
            - /tmp/healthy
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 2
        timeoutSeconds: 2
```

---

## 4. Verification and failure testing

### 4.1 Test startup probe
```bash
kubectl apply -f 01-startup-probe.yaml
kubectl get pod startup-probe-pod -w
```

Terminal Output:
```text
pod/startup-probe-pod created

NAME                READY   STATUS    RESTARTS   AGE
startup-probe-pod   0/1     Running   0          5s
startup-probe-pod   0/1     Running   0          15s
startup-probe-pod   1/1     Running   0          25s
```

Notice the pod stayed in `0/1` without restarting until the 20-second initialization finished and touched `/tmp/started`.

<img src="https://github.com/user-attachments/assets/e8e368ed-fcb4-41b2-b239-83b7b2da3e87" alt="Startup probe delaying readiness until initialization completes" width="100%" />

### 4.2 Test readiness probe with Service Endpoints
```bash
kubectl apply -f 02-readiness-probe.yaml
kubectl expose pod readiness-probe-pod --port=80 --name=readiness-svc

# Check endpoints
kubectl get endpoints readiness-svc
```

Terminal Output:
```text
pod/readiness-probe-pod created
service/readiness-svc exposed

NAME            ENDPOINTS         AGE
readiness-svc   10.244.0.15:80    12s
```

Now simulate a failure by renaming the index file:
```bash
kubectl exec readiness-probe-pod -- mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.bak
sleep 8
kubectl get endpoints readiness-svc
kubectl get pod readiness-probe-pod
```

Output:
```text
NAME            ENDPOINTS   AGE
readiness-svc   <none>      45s

NAME                  READY   STATUS    RESTARTS   AGE
readiness-probe-pod   0/1     Running   0          50s
```

The pod is still running (not restarted), but its IP was safely removed from the service endpoints so users do not receive HTTP 404 errors.

<img src="https://github.com/user-attachments/assets/498d5ff8-a57c-4456-a4b6-6f2db3e0296f" alt="Readiness probe removing unhealthy pod from service endpoints" width="100%" />

### 4.3 Test liveness probe automatic recovery
```bash
kubectl apply -f 03-liveness-probe.yaml
kubectl get pod liveness-probe-pod -w
```

Observed event log:
```text
NAME                 READY   STATUS    RESTARTS   AGE
liveness-probe-pod   1/1     Running   0          5s
liveness-probe-pod   1/1     Running   0          20s
liveness-probe-pod   1/1     Running   0          30s
liveness-probe-pod   1/1     Running   1 (1s ago) 40s
```

Inspect events to verify Kubelet triggered the restart:
```bash
kubectl describe pod liveness-probe-pod | grep -E "Liveness|Killing"
```

Output:
```text
  Warning  Unhealthy  4s (x2 over 9s)   kubelet  Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    4s                kubelet  Container resilient-app failed liveness probe, will be restarted
```

<img src="https://github.com/user-attachments/assets/5ce4a746-0e11-4628-88f4-fd45e430890f" alt="Liveness probe triggering automatic container restart" width="100%" />
