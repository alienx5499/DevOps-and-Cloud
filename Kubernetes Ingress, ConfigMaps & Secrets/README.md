# Kubernetes Ingress, ConfigMaps & Secrets: Application Configuration, Security & Layer 7 Routing

Comprehensive practical implementation covering runtime configuration decoupling, sensitive credential management, Base64 encoding mechanics, NGINX Ingress Controller activation, path/virtual-host routing, and TLS termination based on the SST DevOps & Cloud curriculum.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Architecture: Configuration, Security & Layer 7 Routing

<img src="https://github.com/user-attachments/assets/4e9fcb1f-9b79-4bed-9749-48fb399c38ac" alt="Kubernetes Ingress, ConfigMaps and Secrets Architecture" width="100%" />

---

## 1. Task 1: Non-Sensitive Configuration Decoupling via ConfigMaps

Decouple environment-specific runtime configurations (e.g. `ENVIRONMENT`, `LOG_LEVEL`, `PORT`, `DEFAULT_CURRENCY`) from container images by storing them in a declarative `ConfigMap`.

### 1.1 Manifest (`01-configmap.yaml`)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: yatri-app-config
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "info"
  PORT: "8080"
  DEFAULT_CURRENCY: "INR"
```

### 1.2 Commands:
```bash
kubectl apply -f 01-configmap.yaml
kubectl get configmap yatri-app-config
kubectl describe configmap yatri-app-config
kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}' && echo ""
kubectl get configmap yatri-app-config -o jsonpath='{.data.LOG_LEVEL}' && echo ""
```

### Terminal Output:
```text
configmap/yatri-app-config created

NAME               DATA   AGE
yatri-app-config   4      6s

Name:         yatri-app-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
DEFAULT_CURRENCY:
----
INR
ENVIRONMENT:
----
production
LOG_LEVEL:
----
info
PORT:
----
8080

production
info
```

<img src="https://github.com/user-attachments/assets/785bedbe-7f70-4531-8a2f-aecca7633a8f" alt="ConfigMap Creation and Key Inspection" width="100%" />

---

## 2. Task 2: ConfigMap Live Update & Pod Immobility Verification Drill

Prove that updating an existing `ConfigMap` does not automatically update environment variables inside already-running containers, and demonstrate that a zero-downtime rolling restart propagates the update.

### Commands:
```bash
# 1. Dynamically patch ConfigMap value
kubectl patch configmap yatri-app-config --type merge -p '{"data":{"LOG_LEVEL":"debug"}}'

# 2. Inspect ConfigMap to confirm change
kubectl get configmap yatri-app-config -o jsonpath='{.data.LOG_LEVEL}' && echo ""

# 3. Trigger rolling restart to propagate changes to pods
kubectl rollout restart deployment yatri-backend 2>/dev/null || echo "Pods will consume updated ConfigMap on next restart"
```

### Terminal Output:
```text
configmap/yatri-app-config patched
debug
```

<img src="https://github.com/user-attachments/assets/8628c5af-c652-4dac-9c4b-c562410d8342" alt="ConfigMap Live Patching and Propagation Verification" width="100%" />

---

## 3. Task 3: Sensitive Data Isolation via Kubernetes Secrets & Base64 Mechanics

Construct an `Opaque` Kubernetes Secret storing database credentials. Retrieve and decode masked credentials using JSONPath piped to Base64 decoding.

### 3.1 Manifest (`02-secret.yaml`)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: yatri-db-secret
type: Opaque
data:
  DB_USER: cG9zdGdyZXM=
  DB_PASSWORD: U3VwZXJTZWNyZXREQVBhc3MxMjM=
```

### 3.2 Commands:
```bash
kubectl apply -f 02-secret.yaml
kubectl get secret yatri-db-secret
kubectl describe secret yatri-db-secret

# Imperatively decode base64 values
kubectl get secret yatri-db-secret -o jsonpath='{.data.DB_USER}' | base64 --decode && echo ""
kubectl get secret yatri-db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode && echo ""
```

### Terminal Output:
```text
secret/yatri-db-secret created

NAME              TYPE     DATA   AGE
yatri-db-secret   Opaque   2      9s

Name:         yatri-db-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
DB_PASSWORD:  20 bytes
DB_USER:      8 bytes

postgres
SuperSecretDAPass123
```

<img src="https://github.com/user-attachments/assets/75893c53-c2af-4be5-9424-367b447b4caa" alt="Secret Creation and Base64 Decoding" width="100%" />

---

## 4. Task 4: The Trailing Newline Secret Gotcha & Authentication Failure Analysis

Demonstrate the critical bug where standard `echo` appends an invisible trailing newline character (`\n` / ASCII `0x0A`), corrupting credentials and causing authentication failures.

### Commands:
```bash
# Standard echo (Includes trailing newline \n)
echo "password" | base64

# Echo with -n (Preserves exact binary string without newline)
echo -n "password" | base64
```

### Terminal Output:
```text
cGFzc3dvcmQK
cGFzc3dvcmQ=
```

### Why This Fails in Production:
- `echo "password"` produces 9 bytes: `p-a-s-s-w-o-r-d-\n`. Base64 encodes this to `cGFzc3dvcmQK`.
- When PostgreSQL or MySQL authenticates the user, it compares against the hash of `"password\n"`, resulting in `Access Denied for user`.
- **Hygiene Rule:** Always use `echo -n "secret" | base64` or write to a file with `printf "%s" "secret" | base64`.

<img src="https://github.com/user-attachments/assets/b3dc4a0f-e8ed-4e59-975a-930eb852cf25" alt="Trailing Newline Secret Base64 Comparison" width="100%" />

---

## 5. Task 5: Enterprise Secret Management & Pipeline Integration Analysis

### Architectural Comparison: Kubernetes Native vs External Secret Stores

| Dimension | Native Kubernetes Secrets | HashiCorp Vault | AWS Secrets Manager / Azure Key Vault |
| :--- | :--- | :--- | :--- |
| **At-Rest Security** | Base64 encoded by default; requires KMS plugin for etcd encryption | AES-256 encryption with hardware HSM unsealing keys | Encrypted with AWS KMS / Azure Key Vault customer-managed keys |
| **Credential Rotation** | Manual manifest redeployment | Automated dynamic secrets with TTL leasing | Automated Lambda/event-driven rotation schedules |
| **Access Control** | Kube RBAC at namespace level | Fine-grained token policies and dynamic roles | IAM roles, ABAC, temporary STS credentials |
| **Audit Logging** | Kubernetes API Server audit logs | Complete tamper-proof secret access audit trail | CloudTrail / Azure Activity Log compliance audits |

### Production Integration Pattern (External Secrets Operator - ESO):
Instead of committing Base64 strings to Git, enterprises deploy the **External Secrets Operator (ESO)**:
1. Developers commit an `ExternalSecret` custom resource containing only key references.
2. The ESO controller authenticates to AWS Secrets Manager / HashiCorp Vault via IAM OIDC.
3. The operator automatically synchronizes the secret into a local Kubernetes `Secret` inside the pod namespace.

---

## 6. Task 6: Combined ConfigMap and Secret Pod Injection Architecture

Deploy a microservice pod consuming non-sensitive configuration in bulk (`envFrom: configMapRef`) and sensitive credentials with granular mapping (`env.valueFrom.secretKeyRef`).

### 6.1 Commands:
```bash
# Apply combined frontend, backend, configmap, and secret
kubectl apply -f 01-configmap.yaml
kubectl apply -f 02-secret.yaml
kubectl apply -f 03-combined-app.yaml

# Wait for backend pods to become ready
kubectl rollout status deployment/yatri-backend --timeout=60s

# Verify injected environment variables inside container
BACKEND_POD=$(kubectl get pods -l app=yatri-backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $BACKEND_POD -- env | grep -E "ENVIRONMENT|LOG_LEVEL|PORT|DB_PASSWORD"
```

### Terminal Output:
```text
deployment.apps/yatri-backend created
service/yatri-backend-service created
deployment.apps/yatri-frontend created
service/yatri-frontend-service created

deployment "yatri-backend" successfully rolled out

ENVIRONMENT=production
LOG_LEVEL=debug
PORT=8080
DB_PASSWORD=SuperSecretDAPass123
```

<img src="https://github.com/user-attachments/assets/bcbc30ec-c21b-4b8f-a395-bfcb20072aa7" alt="Combined ConfigMap and Secret Pod Injection" width="100%" />

---

## 7. Task 7: Architectural Study — Ingress Resource vs. Ingress Controller

<img src="https://github.com/user-attachments/assets/9bf15acb-26d2-479d-b522-8a53a3f10e62" alt="Ingress Resource vs Ingress Controller Architecture" width="100%" />

- **Ingress Resource:** A Kubernetes API object containing declarative routing rules (hosts, paths, backends, and TLS certs). It does nothing on its own without a controller.
- **Ingress Controller:** An active reverse proxy daemon (NGINX, Traefik, HAProxy, Envoy) running as a Pod that continuously watches the API server, reconciles Ingress rules, and executes Layer 7 routing.

---

## 8. Task 8: NGINX Ingress Controller Activation & Lifecycle Verification

Enable the NGINX Ingress Controller addon on Minikube and verify that the ingress controller pods reach `Running` and `Ready` states.

### Commands:
```bash
# Enable Ingress addon on Minikube
minikube addons enable ingress

# Verify ingress-nginx namespace pods
kubectl get pods -n ingress-nginx
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
```

### Terminal Output:
```text
💡  ingress is an addon maintained by Kubernetes.
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled

pod/ingress-nginx-controller-d7cd8c989-ddr2z condition met

NAME                                       READY   STATUS      RESTARTS        AGE
ingress-nginx-admission-create-s7mw7       0/1     Completed   0               2m41s
ingress-nginx-admission-patch-kvg2v        0/1     Completed   2 (2m24s ago)   2m41s
ingress-nginx-controller-d7cd8c989-ddr2z   1/1     Running     0               2m41s
```

<img src="https://github.com/user-attachments/assets/66688a8b-865d-43e6-a8d6-731aede3263b" alt="Ingress Controller Activation and Readiness" width="100%" />

---

## 9. Task 9: Local DNS Resolution & System Hosts File Mapping

Map local simulated domains (`yatri.local`, `portal.campus.local`, `api.campus.local`) to the Minikube IP address so traffic routes correctly through host network adapters.

### Commands:
```bash
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP is: $MINIKUBE_IP"

# Demonstrate DNS resolution mapping
echo "$MINIKUBE_IP yatri.local portal.campus.local api.campus.local secure.yatri.local"
```

### Terminal Output:
```text
Minikube IP is: 192.168.49.2
192.168.49.2 yatri.local portal.campus.local api.campus.local secure.yatri.local
```

<img src="https://github.com/user-attachments/assets/261c0b92-3115-451b-a714-e670ad31d4ad" alt="Minikube IP and Local Hosts Domain Mapping" width="100%" />

---

## 10. Task 10: Layer 7 Path-Based Routing Implementation

Route requests under a single host domain (`yatri.local`):
- Root requests (`/`) route to `yatri-frontend-service`.
- API requests (`/api`) route to `yatri-backend-service` with URL rewriting (`rewrite-target: /$2`).

### 10.1 Manifest (`04-ingress-path.yaml`)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yatri-path-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - host: yatri.local
      http:
        paths:
          - path: /()(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-frontend-service
                port:
                  number: 80
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-backend-service
                port:
                  number: 80
```

### 10.2 Commands:
```bash
kubectl apply -f 04-ingress-path.yaml
kubectl get ingress yatri-path-ingress

# Test path routing via Ingress Controller using curl-client
kubectl exec -it curl-client -- curl -s -H "Host: yatri.local" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/ | grep -i "<title>"
kubectl exec -it curl-client -- curl -s -H "Host: yatri.local" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/api | grep -i "<title>"
```

### Terminal Output:
```text
ingress.networking.k8s.io/yatri-path-ingress created

NAME                 CLASS   HOSTS         ADDRESS   PORTS   AGE
yatri-path-ingress   nginx   yatri.local             80      5s

<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
```

<img src="https://github.com/user-attachments/assets/e43dbe56-103d-40a9-9d9c-519b073baea1" alt="Path-Based Ingress Routing via NGINX Controller" width="100%" />

---

## 11. Task 11: Virtual Host-Based Routing (Subdomain Routing)

Route traffic based on distinct virtual host subdomains sharing the same single entry IP address:
- `portal.campus.local` -> `yatri-frontend-service`
- `api.campus.local` -> `yatri-backend-service`

### 11.1 Manifest (`05-ingress-subdomain.yaml`)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: campus-virtual-host-ingress
spec:
  rules:
    - host: portal.campus.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: yatri-frontend-service
                port:
                  number: 80
    - host: api.campus.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: yatri-backend-service
                port:
                  number: 80
```

### 11.2 Commands:
```bash
kubectl apply -f 05-ingress-subdomain.yaml
kubectl get ingress campus-virtual-host-ingress

# Test virtual host routing via Ingress Controller using curl-client
kubectl exec -it curl-client -- curl -s -H "Host: portal.campus.local" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/ | grep -i "<title>"
kubectl exec -it curl-client -- curl -s -H "Host: api.campus.local" http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/ | grep -i "<title>"
```

### Terminal Output:
```text
ingress.networking.k8s.io/campus-virtual-host-ingress created

NAME                          CLASS   HOSTS                                  ADDRESS   PORTS   AGE
campus-virtual-host-ingress   nginx   portal.campus.local,api.campus.local             80      6s

<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
```

<img src="https://github.com/user-attachments/assets/59ac4518-5582-40fa-9525-45fef0b129be" alt="Subdomain Virtual Host Ingress Routing" width="100%" />

---

## 12. Task 12: Hybrid Ingress Routing Architecture

Combining both host-based virtual routing and path-based routing in a single consolidated enterprise Ingress manifest:

<img src="https://github.com/user-attachments/assets/a38591ed-1152-4449-b0e2-eaae16fc4480" alt="Hybrid Ingress Routing Architecture" width="100%" />

---

## 13. Task 13: Ingress TLS/HTTPS Termination & Secret Binding

Generate a self-signed SSL/TLS certificate pair using `openssl`, create a `kubernetes.io/tls` secret, bind it under `spec.tls`, and verify HTTPS termination on port `443`.

### 13.1 Commands:
```bash
# 1. Generate self-signed certificate and private key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=secure.yatri.local/O=Yatri"

# 2. Create TLS Secret
kubectl create secret tls yatri-tls-cert --cert=tls.crt --key=tls.key

# 3. Apply TLS Ingress
kubectl apply -f 06-ingress-tls.yaml
kubectl get ingress yatri-tls-ingress

# 4. Verify HTTPS termination on port 443 with TLS handshake verification
kubectl exec -it curl-client -- curl -k -v -H "Host: secure.yatri.local" https://ingress-nginx-controller.ingress-nginx.svc.cluster.local/ 2>&1 | grep -E "Server certificate|SSL connection using|HTTP/1.1 200"

# 5. Clean up temporary cert files
rm -f tls.key tls.crt
```

### Terminal Output:
```text
secret/yatri-tls-cert created
ingress.networking.k8s.io/yatri-tls-ingress created

NAME                CLASS   HOSTS                ADDRESS   PORTS     AGE
yatri-tls-ingress   nginx   secure.yatri.local             80, 443   4s

* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / RSASSA-PSS
* Server certificate:
```

<img src="https://github.com/user-attachments/assets/85a9b5ef-f0af-4fee-9371-b98a5ba880e5" alt="Ingress TLS HTTPS Termination on Port 443" width="100%" />

---

## 14. Task 14: End-to-End Microservice Teardown & Automation Cleanliness

Verify that all workloads, configurations, secrets, and routing resources tear down cleanly:

```bash
kubectl delete -f 06-ingress-tls.yaml 2>/dev/null
kubectl delete -f 05-ingress-subdomain.yaml 2>/dev/null
kubectl delete -f 04-ingress-path.yaml 2>/dev/null
kubectl delete -f 03-combined-app.yaml 2>/dev/null
kubectl delete -f 02-secret.yaml 2>/dev/null
kubectl delete -f 01-configmap.yaml 2>/dev/null
kubectl delete secret yatri-tls-cert 2>/dev/null
```

### Terminal Output:
```text
ingress.networking.k8s.io "yatri-tls-ingress" deleted from default namespace
ingress.networking.k8s.io "campus-virtual-host-ingress" deleted from default namespace
ingress.networking.k8s.io "yatri-path-ingress" deleted from default namespace
deployment.apps "yatri-backend" deleted from default namespace
service "yatri-backend-service" deleted from default namespace
deployment.apps "yatri-frontend" deleted from default namespace
service "yatri-frontend-service" deleted from default namespace
secret "yatri-db-secret" deleted from default namespace
configmap "yatri-app-config" deleted from default namespace
secret "yatri-tls-cert" deleted from default namespace
pod "curl-client" deleted from default namespace
```

<img src="https://github.com/user-attachments/assets/f6f9ea3f-d83f-40fb-86c7-376d7b40034f" alt="End-to-End Infrastructure Teardown" width="100%" />
