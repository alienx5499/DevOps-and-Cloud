# Kubernetes Networking & Services: Service Discovery, Routing & Ingress

Comprehensive implementation and architectural deep-dive into Kubernetes Service abstractions, packet routing, CoreDNS resolution, and workload controller persistence based on the SST DevOps & Cloud curriculum.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Service Architecture Overview

A Kubernetes `Service` is an abstraction defining a logical set of Pods and a policy by which to access them (frequently referred to as a microservice). Services provide stable virtual IPs (`ClusterIP`) and DNS names that remain invariant even as backend pods are dynamically rescheduled across nodes.

<img src="https://github.com/user-attachments/assets/881ea7c3-dd4b-4e4c-9574-01c1e57da0ae" alt="Kubernetes Service Architecture" width="100%" />


---

## 1. Task 1: Kubernetes Port Architecture & Clarification Drill

Kubernetes networking defines 4 distinct port parameters that control traffic ingress from external clients down to container processes:

<img src="https://github.com/user-attachments/assets/42386e9b-0fa0-4fbe-833f-9b6c876d353e" alt="Kubernetes Port Architecture Diagram" width="100%" />

### Port Definition Matrix:

| Port Field | Layer / Location | Typical Value | Purpose & Boundaries |
| :--- | :--- | :--- | :--- |
| **`nodePort`** | Node Host Interface | `30000–32767` | Exposes service externally on every cluster node's IP address. |
| **`port`** | Service Virtual IP | `80`, `8080`, etc. | Internal port exposed on the stable cluster-internal virtual IP. |
| **`targetPort`** | Pod Network Interface | `80`, `3000`, etc. | Destination port on the pod where traffic is routed by the Service. |
| **`containerPort`** | Container Process Socket | `80`, `8080`, etc. | Port listening inside the container image; purely informational documentation. |

### 1.2 Inspection Commands:
```bash
kubectl explain pod.spec.containers.ports.containerPort
kubectl explain service.spec.ports
```

<img src="https://github.com/user-attachments/assets/8a4b1d05-0f7c-4660-8775-996f468ded1e" alt="Kubernetes Port Architecture and Explain Inspection" width="100%" />

---

## 2. Task 2: Type 1 Service — ClusterIP (Default Internal Networking)

Deploy a 3-replica backend application, expose it via a default `ClusterIP` service, verify automatic endpoint discovery, and test internal DNS resolution and FQDN reachability from an ephemeral test pod.

### 2.1 Manifests (`01-clusterip.yaml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-clusterip
  labels:
    app: web-clusterip
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-clusterip
  template:
    metadata:
      labels:
        app: web-clusterip
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service-clusterip
spec:
  type: ClusterIP
  selector:
    app: web-clusterip
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 80
```

### 2.2 Execution & Verification Commands:
```bash
# 1. Apply backend deployment, ClusterIP service, and diagnostic pod
kubectl apply -f 01-clusterip.yaml
kubectl apply -f curl-client.yaml

# 2. Verify pods, service allocation, and endpoints
kubectl get pods -l app=web-clusterip -o wide
kubectl get svc web-service-clusterip
kubectl get endpoints web-service-clusterip

# 3. Test internal resolution via short name and full FQDN
kubectl exec -it curl-client -- curl -s http://web-service-clusterip:8080 | grep -i "<title>"
kubectl exec -it curl-client -- curl -s http://web-service-clusterip.default.svc.cluster.local:8080 | grep -i "<title>"

# 4. Clean up
kubectl delete -f 01-clusterip.yaml
```

### Terminal Output:
```text
deployment.apps/web-app-clusterip created
service/web-service-clusterip created
pod/curl-client created

NAME                                READY   STATUS    RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
web-app-clusterip-5d8c7dccd-fknk6   1/1     Running   0          112s   10.244.0.65   minikube   <none>           <none>
web-app-clusterip-5d8c7dccd-k682t   1/1     Running   0          112s   10.244.0.63   minikube   <none>           <none>
web-app-clusterip-5d8c7dccd-k8wkg   1/1     Running   0          112s   10.244.0.64   minikube   <none>           <none>

NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/web-service-clusterip   ClusterIP   10.110.162.161   <none>        8080/TCP   118s

NAME                              ENDPOINTS                                      AGE
endpoints/web-service-clusterip   10.244.0.63:80,10.244.0.64:80,10.244.0.65:80   118s

<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
```

<img src="https://github.com/user-attachments/assets/b1869d8b-ea6c-4135-b433-83d7fa3d195d" alt="ClusterIP Backend Deployment and Client Pod Creation" width="100%" />
<img src="https://github.com/user-attachments/assets/eb9a9938-5852-4ea7-beed-47389f19cec2" alt="ClusterIP Service Allocation and Active Endpoints" width="100%" />
<img src="https://github.com/user-attachments/assets/92a65dfd-b599-4e8b-a4cc-e28b2b9e6a01" alt="Internal Service Name and FQDN Curl Resolution" width="100%" />

---

## 3. Task 3: Type 2 Service — NodePort (Host-Level External Ingress)

Expose a web service externally on a high node port (`30000–32767`) on every cluster node host interface.

### 3.1 Manifest (`02-nodeport.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-nodeport
spec:
  type: NodePort
  selector:
    app: web-clusterip
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
```

### 3.2 Commands:
```bash
# 1. Deploy backend and NodePort service
kubectl apply -f 01-clusterip.yaml
kubectl apply -f 02-nodeport.yaml

# 2. Inspect NodePort mapping
kubectl get svc web-service-nodeport

# 3. Test HTTP connectivity
curl -I http://$(minikube ip):30080 2>/dev/null || minikube service web-service-nodeport --url

# 4. Clean up
kubectl delete -f 02-nodeport.yaml -f 01-clusterip.yaml
```

### Terminal Output:
```text
service/web-service-nodeport created

NAME                   TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
web-service-nodeport   NodePort   10.103.47.63   <none>        80:30080/TCP   6s

HTTP/1.1 200 OK
Server: nginx/1.27.0
Content-Type: text/html
Content-Length: 615
Connection: keep-alive
```

<img src="https://github.com/user-attachments/assets/c0cfb7f9-5a98-4111-bd8b-82f93a6a8d1f" alt="NodePort Service Creation and Port Mapping" width="100%" />

---

## 4. Task 4: Type 3 Service — LoadBalancer (Cloud-Native Ingress Simulation)

Deploy an externally reachable Service using `type: LoadBalancer`. In cloud environments (AWS, GCP, Azure), this triggers dynamic external load balancer provisioning; on Minikube, `minikube tunnel` simulates the cloud IP assignment layer.

### 4.1 Manifest (`03-loadbalancer.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web-clusterip
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### 4.2 Commands:
```bash
# 1. Deploy backend and LoadBalancer service
kubectl apply -f 01-clusterip.yaml
kubectl apply -f 03-loadbalancer.yaml

# 2. Inspect LoadBalancer status
kubectl get svc web-service-loadbalancer

# 3. Verify underlying port mappings
kubectl describe svc web-service-loadbalancer | grep -E "Type|IP|Port|Endpoints"

# 4. Clean up
kubectl delete -f 03-loadbalancer.yaml -f 01-clusterip.yaml
```

### Terminal Output:
```text
service/web-service-loadbalancer created

NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
web-service-loadbalancer   LoadBalancer   10.108.26.16   <pending>     80:30500/TCP   5s

Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.108.26.16
IPs:                      10.108.26.16
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  30500/TCP
Endpoints:                10.244.0.63:80,10.244.0.65:80,10.244.0.64:80
```

<img src="https://github.com/user-attachments/assets/1008cd03-bdc9-4eed-b8ee-9321befbdb17" alt="LoadBalancer Service Creation and Port Mapping" width="100%" />

---

## 5. Task 5: Type 4 Service — ExternalName (CoreDNS CNAME Alias Redirection)

Configure an `ExternalName` service that acts as an internal DNS CNAME alias pointing to an external domain (`api.github.com`). Notice that no `clusterIP` or `Endpoints` are created—CoreDNS directly returns a `CNAME` record.

### 5.1 Manifest (`04-externalname.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-database-service
spec:
  type: ExternalName
  externalName: api.github.com
```

### 5.2 Commands:
```bash
# 1. Apply ExternalName service
kubectl apply -f 04-externalname.yaml

# 2. Verify service details (Notice CLUSTER-IP: <none> and EXTERNAL-IP: api.github.com)
kubectl get svc external-database-service

# 3. Test DNS CNAME resolution from inside client pod (FQDN with trailing dot to bypass search paths)
kubectl exec -it curl-client -- nslookup external-database-service.default.svc.cluster.local.

# 4. Clean up
kubectl delete -f 04-externalname.yaml
```

### Terminal Output:
```text
service/external-database-service created

NAME                        TYPE           CLUSTER-IP   EXTERNAL-IP      PORT(S)   AGE
external-database-service   ExternalName   <none>       api.github.com   <none>    4s

Server:         10.96.0.10
Address:        10.96.0.10:53

external-database-service.default.svc.cluster.local     canonical name = api.github.com

external-database-service.default.svc.cluster.local     canonical name = api.github.com
Name:   api.github.com
Address: 20.207.73.85
```

<img src="https://github.com/user-attachments/assets/f68e4e2b-d68d-4b54-9350-0cb1f0435980" alt="ExternalName Service CNAME DNS Resolution" width="100%" />

---

## 6. Task 6: Type 5 Service — Headless Service (`clusterIP: None` & Stateful Workloads)

Deploy a Headless Service (`clusterIP: None`) paired with a `StatefulSet`. Unlike standard Services that return a single virtual IP, CoreDNS directly returns the individual `A` records for all matching Pod IPs, enabling direct peer-to-peer and ordinal pod addressing (`web-stateful-0.web-service-headless`).

### 6.1 Manifest (`05-headless-statefulset.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-headless
spec:
  clusterIP: None
  selector:
    app: web-headless
  ports:
    - port: 80
      name: web
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: "web-service-headless"
  replicas: 3
  selector:
    matchLabels:
      app: web-headless
  template:
    metadata:
      labels:
        app: web-headless
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
              name: web
```

### 6.2 Commands:
```bash
# 1. Apply Headless service and StatefulSet
kubectl apply -f 05-headless-statefulset.yaml
kubectl rollout status statefulset/web-stateful --timeout=60s

# 2. Inspect Headless Service (Notice CLUSTER-IP is explicitly None)
kubectl get svc web-service-headless
kubectl get pods -l app=web-headless -o wide

# 3. Test DNS resolution: Returns all 3 pod IPs directly (FQDN with trailing dot to bypass search paths)
kubectl exec -it curl-client -- nslookup web-service-headless.default.svc.cluster.local.

# 4. Query an individual Pod directly via its stable ordinal FQDN
kubectl exec -it curl-client -- curl -s http://web-stateful-0.web-service-headless:80 | grep -i "<title>"

# 5. Clean up
kubectl delete -f 05-headless-statefulset.yaml
```

### Terminal Output:
```text
service/web-service-headless created
statefulset.apps/web-stateful created
partitioned roll out complete: 3 new pods have been updated...

NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web-service-headless   ClusterIP   None         <none>        80/TCP    11s

NAME             READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
web-stateful-0   1/1     Running   0          16s   10.244.0.70   minikube   <none>           <none>
web-stateful-1   1/1     Running   0          16s   10.244.0.71   minikube   <none>           <none>
web-stateful-2   1/1     Running   0          15s   10.244.0.72   minikube   <none>           <none>

Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   web-service-headless.default.svc.cluster.local
Address: 10.244.0.72
Name:   web-service-headless.default.svc.cluster.local
Address: 10.244.0.71
Name:   web-service-headless.default.svc.cluster.local
Address: 10.244.0.70

<title>Welcome to nginx!</title>
```

<img src="https://github.com/user-attachments/assets/364657a8-f8a8-4b72-b0ab-86d690f4f9a5" alt="Headless Service DNS and Ordinal Addressing" width="100%" />

---

## 7. Task 7: Services Without Selectors (Manual Endpoints Mapping)

Define a custom Service without a label selector and manually bind it to an external legacy database IP address using a matching `Endpoints` object.

### 7.1 Manifest (`06-empty-endpoints.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-legacy-db
spec:
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-legacy-db
subsets:
  - addresses:
      - ip: 192.168.1.150
    ports:
      - port: 3306
```

### 7.2 Commands:
```bash
# 1. Create service without selector and verify endpoints
kubectl apply -f 06-empty-endpoints.yaml
kubectl get svc external-legacy-db
kubectl get endpoints external-legacy-db

# 2. Clean up
kubectl delete -f 06-empty-endpoints.yaml
```

### Terminal Output:
```text
service/external-legacy-db created
endpoints/external-legacy-db created

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
external-legacy-db   ClusterIP   10.98.171.73   <none>        3306/TCP   4s

NAME                 ENDPOINTS            AGE
external-legacy-db   192.168.1.150:3306   9s
```

<img src="https://github.com/user-attachments/assets/0b15ce8e-6a1d-45c3-a213-c178a74967e0" alt="Manual Endpoints Mapping Without Selectors" width="100%" />

---

## 8. Task 8: FQDN & CoreDNS Deep Dive Architecture Analysis

Inspect the DNS configuration injected by kubelet into every pod container (`/etc/resolv.conf`) and document the latency penalty of `ndots:5`.

### 8.1 Inspection Commands:
```bash
# 1. Inspect CoreDNS daemons
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

# 2. Inspect /etc/resolv.conf inside running pod
kubectl exec -it curl-client -- cat /etc/resolv.conf

# 3. Test DNS search domain expansion (clean FQDN with trailing dot)
kubectl exec -it curl-client -- nslookup kubernetes.default.svc.cluster.local.
```

### 8.2 Terminal Output:
```text
NAME                       READY   STATUS    RESTARTS      AGE   IP           NODE       NOMINATED NODE   READINESS GATES
coredns-559f6c778d-k4kfr   1/1     Running   1 (44h ago)   44h   10.244.0.2   minikube   <none>           <none>

search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   kubernetes.default.svc.cluster.local
Address: 10.96.0.1
```

### 8.3 The `ndots:5` Latency Mechanism Explained
- When an application queries an external domain with fewer than 5 dots (e.g. `api.github.com` has 2 dots), the DNS resolver considers it non-absolute.
- It sequentially appends local cluster search paths first:
  1. `api.github.com.default.svc.cluster.local` (NXDOMAIN)
  2. `api.github.com.svc.cluster.local` (NXDOMAIN)
  3. `api.github.com.cluster.local` (NXDOMAIN)
  4. `api.github.com.` (Final SUCCESS)
- **Production Solution:** Append a trailing dot to absolute external hostnames (e.g., `api.github.com.`) to force immediate authoritative lookup, eliminating 3 unnecessary DNS round-trips.

<img src="https://github.com/user-attachments/assets/640af569-e74c-46e2-ab92-a1b58cc80885" alt="CoreDNS and Container Resolv Conf Inspection" width="100%" />

---

## 9. Task 9: Pod Identity Invariance Drill — Deployment vs. StatefulSet

Contrast ephemeral replica identity in stateless Deployments against deterministic ordinal identity in StatefulSets by killing an active pod in each workload.

### 9.1 Commands:
```bash
# 1. Apply both workloads
kubectl apply -f 01-clusterip.yaml
kubectl apply -f 05-headless-statefulset.yaml
sleep 6

# 2. Observe initial pod identities
kubectl get pods -l app=web-clusterip
kubectl get pods -l app=web-headless

# 3. Delete a pod from each controller
DEPLOY_POD=$(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $DEPLOY_POD
kubectl delete pod web-stateful-0

# 4. Check resurrected pod identities
sleep 4
kubectl get pods -l app=web-clusterip
kubectl get pods -l app=web-headless

# 5. Clean up
kubectl delete -f 01-clusterip.yaml -f 05-headless-statefulset.yaml
```

### Terminal Output:
```text
# Initial state:
web-app-clusterip-5d8c7dccd-fknk6   1/1     Running   0          30m
web-stateful-0                      1/1     Running   0          7m30s

# Pod deletion:
pod "web-app-clusterip-5d8c7dccd-fknk6" deleted from default namespace
pod "web-stateful-0" deleted from default namespace

# Recreated state:
web-app-clusterip-5d8c7dccd-k2xtg   1/1     Running   0          12s   <-- Brand-new random hash identity
web-stateful-0                      1/1     Running   0          11s   <-- Exact invariant ordinal identity resurrected
```

<img src="https://github.com/user-attachments/assets/cce49f13-333b-4d98-9381-032876bdddd9" alt="Pod Identity Invariance Drill - Deployment vs StatefulSet" width="100%" />

---

## 10. Task 10: Master Architectural Matrix — Workload Controllers

| Architectural Dimension | Deployment (Stateless) | StatefulSet (Stateful) | DaemonSet (Node-Level) |
| :--- | :--- | :--- | :--- |
| **Pod Identity** | Random hash suffix (`app-76d8b-x9z2p`) | Deterministic ordinal index (`db-0, db-1`) | Node-tied name (`agent-host1`) |
| **Startup / Shutdown** | Parallel, unordered | Strictly sequential (`0 -> 1 -> 2`) | Concurrent across all eligible nodes |
| **Persistent Storage** | Shared volumes (`ReadWriteMany`) | Dedicated per-pod `volumeClaimTemplates` | HostPath / local storage |
| **Primary Network Coupling** | `ClusterIP` / `LoadBalancer` | `Headless Service` (`clusterIP: None`) | HostPort / NodePort |
| **Failover Mechanism** | Ephemeral replacement pod | Invariant identity re-attached to same PVC | Re-scheduled only on node join/reboot |
| **Canonical Workloads** | Web APIs, microservices, stateless apps | MySQL, PostgreSQL, Kafka, ZooKeeper | Fluentbit, Node Exporter, Cilium CNI |

---

## 11. Task 11: Production Cost Optimization & Service Selection Decision Tree

### 11.1 Service Selection Decision Tree

<img src="https://github.com/user-attachments/assets/bb760cb1-b708-4bd3-b2ed-832fa23ea1d1" alt="Service Selection Decision Tree" width="100%" />

### 11.2 The Cloud Anti-Pattern vs. Production Ingress
- **Anti-Pattern:** Creating 20 separate `type: LoadBalancer` services provisions 20 distinct cloud provider Network Load Balancers (NLBs) at ~$18–$25/month each = **$360–$500/month** in idle infrastructure overhead.
- **Production Pattern:** Deploy 1 Cloud Load Balancer in front of an Ingress Controller (e.g. NGINX), multiplexing hundreds of internal `ClusterIP` microservices via path and host routing rules at a fraction of the cost.

---

## 12. Task 12: Minikube Docker-Driver Port Binding & Tunnel Gotcha Analysis

### Root Cause Analysis:
- On macOS and Windows, Docker Desktop executes within an isolated LinuxKit virtual machine hypervisor.
- When running `minikube start --driver=docker`, the Minikube node IP (`192.168.49.2`) resides inside the Docker bridge network on the VM, not on the host macOS network adapter.
- Consequently, hitting `http://<Minikube-IP>:30080` from the host browser results in connection timeouts.

### 12.3 Verification Commands:
```bash
# 1. Apply NodePort service and backend
kubectl apply -f 01-clusterip.yaml
kubectl apply -f 02-nodeport.yaml

# 2. Demonstrate direct connection failure on macOS Docker driver (native timeout)
curl --connect-timeout 2 http://192.168.49.2:30080

# 3. Workaround: Dynamic Local Proxy via minikube service
minikube service web-service-nodeport --url

# 4. Clean up
kubectl delete -f 02-nodeport.yaml -f 01-clusterip.yaml
```

### Terminal Output:
```text
deployment.apps/web-app-clusterip created
service/web-service-clusterip created
service/web-service-nodeport created

curl: (28) Failed to connect to 192.168.49.2 port 30080 after 2001 ms: Timeout was reached

http://127.0.0.1:59752
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.
```

<img src="https://github.com/user-attachments/assets/b4ba7269-7222-4435-ace3-c5862e65b25f" alt="Minikube Docker Driver Port Forwarding Tunnel" width="100%" />
