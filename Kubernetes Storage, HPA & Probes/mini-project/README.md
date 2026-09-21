# Session 13 Mini-Project: Production Web Application with Storage, Health Probes & Autoscaling

A combined production-style workload demonstrating PersistentVolumeClaims, health probes (startup, readiness, and liveness), and Horizontal Pod Autoscaling in a dedicated namespace.

---

## 1. Project architecture

This project connects three Kubernetes concepts into one workflow:
- **Persistent storage:** A 500Mi PVC mounted at `/data` ensuring files survive pod crashes and redeployments.
- **Health monitoring:** Startup, readiness, and liveness probes protecting against slow boots, deadlocks, and sending traffic to broken pods.
- **Autoscaling:** HPA scaling the deployment between 2 and 5 replicas when average CPU usage crosses 50%.

<img width="8192" height="2368" alt="Mini-Project Production Web Application Architecture" src="https://github.com/user-attachments/assets/47103d3c-f8c3-4a64-a1cb-833b99ca5deb" />

---

## 2. Manifest files

The project consists of 5 declarative Kubernetes files:
- `namespace.yaml`: Creates the dedicated `production-webapp` namespace.
- `pvc.yaml`: Claims 500Mi storage with `ReadWriteOnce` access mode.
- `deployment.yaml`: Runs 2 replicas of NGINX with resource requests, all three probes, and volume mounts.
- `service.yaml`: ClusterIP service routing traffic on port 80.
- `hpa.yaml`: Autoscaling configuration targeting 50% CPU utilization.

---

## 3. Step-by-step deployment guide

### 3.1 Create namespace and storage claim
```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Apply the PVC
kubectl apply -f pvc.yaml

# 3. Check PVC status
kubectl get pvc -n production-webapp
```

Terminal Output:
```text
namespace/production-webapp created
persistentvolumeclaim/web-data created

NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
web-data   Bound    pvc-4b123456-789a-bcde-f012-3456789abcde   500Mi      RWO            standard       4s
```

<img src="https://github.com/user-attachments/assets/d0c37b58-932e-485e-b440-5327e927659f" alt="Namespace and PVC creation in production-webapp" width="100%" />

### 3.2 Deploy application and service
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for both pods to become Ready
kubectl get pods -n production-webapp -l app=web-app
```

Terminal Output:
```text
deployment.apps/web-app created
service/web-service created

NAME                       READY   STATUS    RESTARTS   AGE
web-app-7988df964b-abcde   1/1     Running   0          22s
web-app-7988df964b-fghij   1/1     Running   0          22s
```

<img src="https://github.com/user-attachments/assets/9a23bc82-68e0-4e88-a4de-1b0780ff83ad" alt="Deployment pods reaching Ready status with probes active" width="100%" />

### 3.3 Apply Horizontal Pod Autoscaler
```bash
kubectl apply -f hpa.yaml

kubectl get hpa -n production-webapp
```

Terminal Output:
```text
horizontalpodautoscaler.autoscaling/web-app-hpa created

NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   0%/50%    2         5         2          18s
```

<img src="https://github.com/user-attachments/assets/2668e47a-47e0-4b3a-bd5a-467ef1f0ede5" alt="HPA deployed targeting 50 percent CPU" width="100%" />

---

## 4. Verification drills

### 4.1 Drill 1: Storage persistence across pod deletion
Write a file into the mounted `/data` volume, delete the pod, and confirm the replacement pod still has the file:

```bash
# 1. Pick a running pod and write student info to /data
POD_NAME=$(kubectl get pods -n production-webapp -l app=web-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n production-webapp "$POD_NAME" -- sh -c 'echo "Student: Prabal Patra (24BCS10031)" > /data/student.txt'

# 2. Verify file content
kubectl exec -n production-webapp "$POD_NAME" -- cat /data/student.txt
```

Terminal Output:
```text
Student: Prabal Patra (24BCS10031)
```

Now delete the pod:
```bash
kubectl delete pod -n production-webapp "$POD_NAME"

# Wait for the replacement pod to start
kubectl wait --for=condition=Ready pod -l app=web-app -n production-webapp --timeout=60s

# Verify file on the new pod
NEW_POD=$(kubectl get pods -n production-webapp -l app=web-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n production-webapp "$NEW_POD" -- cat /data/student.txt
```

Terminal Output:
```text
pod "web-app-7988df964b-abcde" deleted
pod/web-app-7988df964b-z92kl condition met

Student: Prabal Patra (24BCS10031)
```

<img src="https://github.com/user-attachments/assets/90c9df88-26bc-4b20-9751-9bc912b8e66f" alt="Storage persistence verification across pod recreation" width="100%" />

### 4.2 Drill 2: Service access via port-forward
Forward port 80 to verify the application responds locally:
```bash
kubectl port-forward -n production-webapp svc/web-service 8080:80
```

In another terminal, test with curl:
```bash
curl -I http://localhost:8080
```

Terminal Output:
```text
HTTP/1.1 200 OK
Server: nginx/1.25.4
Content-Type: text/html
Content-Length: 615
Connection: keep-alive
```

<img src="https://github.com/user-attachments/assets/4d484760-e077-4d3f-8156-ddba6439cde1" alt="Service port-forwarding and HTTP 200 response" width="100%" />

### 4.3 Drill 3: Trigger HPA scaling under load
Launch the load generator:
```bash
chmod +x load_generator.sh
./load_generator.sh
```

Monitor autoscaling:
```bash
kubectl get hpa web-app-hpa -n production-webapp -w
```

Observed scaling progression:
```text
NAME          REFERENCE            TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   0%/50%     2         5         2          1m
web-app-hpa   Deployment/web-app   120%/50%   2         5         2          2m
web-app-hpa   Deployment/web-app   90%/50%    2         5         4          3m
web-app-hpa   Deployment/web-app   48%/50%    2         5         5          4m
```

Stop the load and observe cooldown:
```bash
kubectl delete pod load-generator -n production-webapp
kubectl get hpa web-app-hpa -n production-webapp -w
```

Output:
```text
NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   0%/50%    2         5         5          5m
web-app-hpa   Deployment/web-app   0%/50%    2         5         2          10m
```

<img src="https://github.com/user-attachments/assets/30530825-896b-48e1-a2b4-8a3b03686de6" alt="HPA scaling out to 5 replicas and scaling back down" width="100%" />

---

## 5. Troubleshooting guide

### PVC stuck in Pending
- Check status: `kubectl describe pvc web-data -n production-webapp`
- Likely cause: Missing default StorageClass.
- Fix: On minikube, run `minikube addons enable default-storageclass`.

### HPA reports TARGETS: unknown/50%
- Check status: `kubectl top pods -n production-webapp`
- Likely cause: Metrics Server is not active or container spec is missing `resources.requests.cpu`.
- Fix: Enable metrics server with `minikube addons enable metrics-server` and verify `cpu: 100m` request exists in `deployment.yaml`.

### Container restarts repeatedly (CrashLoopBackOff)
- Check status: `kubectl describe pod <pod-name> -n production-webapp`
- Likely cause: Liveness probe path or port is wrong, causing Kubelet to kill the container repeatedly.
- Fix: Verify `httpGet.path` responds with HTTP 200-399.
