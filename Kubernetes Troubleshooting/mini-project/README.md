# Session 14 Mini-Project: Kubernetes Troubleshooting Challenge

Practical end-to-end diagnosis and repair challenge covering container lifecycle failures, image pull errors, Service selector mismatches, and endpoint routing verification.

---

## 1. Architecture

<img width="6261" height="2180" alt="Troubleshooting Challenge Architecture" src="https://github.com/user-attachments/assets/066bc9de-bcb8-45e5-a0a4-52f6b617e5a7" />

---

## 2. Step 1: Deploy the Healthy Application

Deploy the Deployment and Service manifests:
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Verify status:
```bash
kubectl get pods -l app=troubleshooting-app -o wide
kubectl get service troubleshooting-service
```

Expected Terminal Output:
```text
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
troubleshooting-app-76dc594c77-k4p9z   1/1     Running   0          22s   10.244.0.12   minikube   <none>           <none>
troubleshooting-app-76dc594c77-w9x8b   1/1     Running   0          22s   10.244.0.13   minikube   <none>           <none>

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.108.204.112   <none>        80/TCP    22s
```

<img src="https://github.com/user-attachments/assets/da7e8192-6476-4f60-9c22-abe77ad40e70" alt="Healthy deployment and service status" width="100%" />

---

## 3. Step 2: Verify Application Health and In-Cluster Access

Test the application using `logs` and `exec`:
```bash
# Check pod logs
POD_NAME=$(kubectl get pods -l app=troubleshooting-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME

# Execute in-container curl test
kubectl exec -it $POD_NAME -- wget -qO- http://localhost:80 | grep "<title>"
```

Expected Terminal Output:
```text
2026/09/30 11:15:10 [notice] 1#1: start worker processes
<title>Welcome to nginx!</title>
```

<img src="https://github.com/user-attachments/assets/9f804258-3a8e-4941-8f5b-46724475b2be" alt="Pod logs and internal curl test verification" width="100%" />

---

## 4. Step 3: Check Service Routing & Endpoints

Verify that the Service selector successfully connects to the backend pods:
```bash
kubectl describe service troubleshooting-service
kubectl get endpoints troubleshooting-service
```

Expected Terminal Output:
```text
Name:              troubleshooting-service
Namespace:         default
Labels:            app=troubleshooting-app
Selector:          app=troubleshooting-app
Type:              ClusterIP
IP:                10.108.204.112
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         10.244.0.12:80,10.244.0.13:80

NAME                      ENDPOINTS                         AGE
troubleshooting-service   10.244.0.12:80,10.244.0.13:80   1m
```

<img src="https://github.com/user-attachments/assets/1d492b82-b77d-4f63-b2de-0e80ae502fa2" alt="Service details and endpoints populated" width="100%" />

---

## 5. Step 4: Challenge A - Diagnose the Broken Pod

Deploy the broken pod:
```bash
kubectl apply -f broken-pod.yaml
kubectl get pod project-broken-pod
```

Expected Terminal Output:
```text
NAME                 READY   STATUS             RESTARTS   AGE
project-broken-pod   0/1     ImagePullBackOff   0          35s
```

<img src="https://github.com/user-attachments/assets/20d7e70d-59a6-4452-8e62-f3850899058e" alt="Broken pod ImagePullBackOff status" width="100%" />

### Investigation Without Guessing
```bash
kubectl describe pod project-broken-pod
```

Expected Terminal Output:
```text
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  48s                default-scheduler  Successfully assigned default/project-broken-pod to minikube
  Normal   Pulling    20s (x3 over 47s)  kubelet            Pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     19s (x3 over 46s)  kubelet            Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": not found
  Warning  Failed     19s (x3 over 46s)  kubelet            Error: ErrImagePull
  Normal   BackOff    5s (x2 over 45s)   kubelet            Back-off pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     5s (x2 over 45s)   kubelet            Error: ImagePullBackOff
```

### Challenge A Questions & Answers

1. **What is the Pod status?**
   `ImagePullBackOff` (preceded immediately by `ErrImagePull`).
2. **What is the actual error?**
   `rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": not found`.
3. **Which command helped you find the reason?**
   `kubectl describe pod project-broken-pod`, specifically the `Events:` section at the bottom.
4. **What is wrong with the image?**
   The tag `this-tag-does-not-exist` does not exist in the official `library/nginx` repository on Docker Hub.
5. **How would you fix it?**
   Update the container image specification to a verified existing tag such as `nginx:1.27-alpine` or `nginx:latest`.

### Fix and Verification
```bash
kubectl set image pod/project-broken-pod app=nginx:1.27-alpine
# Or delete and recreate with valid image:
kubectl delete pod project-broken-pod
kubectl run project-broken-pod --image=nginx:1.27-alpine --labels=app=troubleshooting-app
kubectl get pod project-broken-pod
```

Expected Terminal Output:
```text
NAME                 READY   STATUS    RESTARTS   AGE
project-broken-pod   1/1     Running   0          11s
```

<img src="https://github.com/user-attachments/assets/af8074de-e2d8-4f8d-8168-7621d35a80d1" alt="Broken pod resolved to Running" width="100%" />

---

## 6. Step 5: Challenge B - Service Selector Mismatch

Intentionally introduce a selector failure on the service:
```bash
kubectl patch service troubleshooting-service -p '{"spec":{"selector":{"app":"wrong-app"}}}'
```

Observe the service and its endpoints:
```bash
kubectl get service troubleshooting-service
kubectl get endpoints troubleshooting-service
```

Expected Terminal Output:
```text
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.108.204.112   <none>        80/TCP    5m

NAME                      ENDPOINTS   AGE
troubleshooting-service   <none>      5m
```

<img src="https://github.com/user-attachments/assets/115ba186-ea83-43d9-88c0-2743a28ef0d0" alt="Service endpoints empty after selector mismatch" width="100%" />

### Investigation
```bash
# Check pod labels
kubectl get pods --show-labels -l app=troubleshooting-app

# Check service selector
kubectl get service troubleshooting-service -o jsonpath='{.spec.selector}' && echo ""
```

Terminal Output shows the mismatch: pods carry `app=troubleshooting-app`, whereas the service selector searches for `app: wrong-app`.

### Fix and Verification
Restore the valid selector:
```bash
kubectl patch service troubleshooting-service -p '{"spec":{"selector":{"app":"troubleshooting-app"}}}'
kubectl get endpoints troubleshooting-service
```

Expected Terminal Output:
```text
NAME                      ENDPOINTS                         AGE
troubleshooting-service   10.244.0.12:80,10.244.0.13:80   6m
```

<img src="https://github.com/user-attachments/assets/0421eeb8-be24-462f-baf6-e2862ff22861" alt="Service endpoints restored" width="100%" />

---

## 7. Troubleshooting Investigation Summary

| Scenario | Symptom Observed | Investigation Command | Root Cause | Solution Applied |
| :--- | :--- | :--- | :--- | :--- |
| **Broken Pod** | `ImagePullBackOff` | `kubectl describe pod project-broken-pod` | Non-existent image tag `this-tag-does-not-exist` | Patched image to `nginx:1.27-alpine` |
| **Broken Service** | `Endpoints: <none>` | `kubectl describe service troubleshooting-service` | Selector `app: wrong-app` did not match pod label | Restored selector to `app: troubleshooting-app` |
| **CrashLoop** | Container restart loop | `kubectl logs <pod> --previous` | Container entrypoint command exited with code 1 | Corrected application startup configuration |

---

## 8. Conceptual Q&A

1. **What does `kubectl get` tell us?**
   It lists high-level state, readiness status, restart counts, and uptime for cluster resources in a concise tabular format.
2. **What is the difference between `get` and `describe`?**
   `get` lists current summary rows from API objects. `describe` gives the detailed object specification, controller status flags, and chronological cluster events.
3. **Why do we use `kubectl logs`?**
   It retrieves stdout and stderr logs emitted directly by application processes, essential for debugging application logic errors and runtime crashes.
4. **When would you use `kubectl exec`?**
   To test network reachability from inside a pod, verify mounted files and environment variables, or run diagnostic tools like `nslookup` and `curl`.
5. **What does `CrashLoopBackOff` mean?**
   The application container repeatedly starts and terminates with an error code. Kubernetes delays subsequent restarts exponentially to protect node resources.
6. **What does `ImagePullBackOff` mean?**
   The container runtime failed to download the image from the registry (due to bad tag, missing repository, or invalid pull credentials) and is pausing before retrying.
7. **Why can a Pod remain `Pending`?**
   The Kubernetes scheduler cannot find a node that meets all pod requirements (insufficient CPU/memory, untolerated node taints, or unsatisfied nodeSelector rules).
8. **Why can a Service have no endpoints?**
   No pods in the namespace match the key-value pairs defined in `spec.selector`, or matching pods exist but are not yet passing their readiness probes.
9. **What is the relationship between a Service selector and Pod labels?**
   The Service selector is a label query. The Endpoints controller automatically adds pod IPs to the Service only if their `metadata.labels` contain exact matches for the selector.
10. **What is Kubernetes DNS?**
    An internal cluster service (CoreDNS) that maps Service names to their ClusterIP addresses, allowing pods to communicate using stable hostnames like `my-service.my-namespace.svc.cluster.local`.
