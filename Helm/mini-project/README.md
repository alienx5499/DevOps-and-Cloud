# Session 15 Mini-Project: Multi-Environment Notes Application with Helm

Complete packaging, templating, multi-environment deployment, and lifecycle management for the SST Notes web application using Helm.

---

## 1. Project Architecture

<img width="5649" height="3305" alt="Notes App Multi-Environment Architecture" src="https://github.com/user-attachments/assets/d14bdd4a-3168-42e0-b714-98b59b119795" />

---

## 2. Chart Layout & Structure

The chart files are organized inside `notes-chart/`:
```text
notes-chart/
  Chart.yaml
  values.yaml
  values-prod.yaml
  templates/
    _helpers.tpl
    configmap.yaml
    deployment.yaml
    service.yaml
```

Verify chart syntax:
```bash
helm lint ./notes-chart
```

Expected Terminal Output:
```text
==> Linting ./notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

<img src="https://github.com/user-attachments/assets/f8a39c6e-a2be-4cd0-b5a7-e30c468ffc1e" alt="Helm lint verification output" width="100%" />

---

## 3. Step 1: Deploy to Development Environment

Deploy the development release using default values:
```bash
helm install notes-dev ./notes-chart
```

Expected Terminal Output:
```text
NAME: notes-dev
LAST DEPLOYED: Wed Sep 30 11:50:12 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

<img src="https://github.com/user-attachments/assets/d0c228e2-56f1-4eb5-8a77-80994ab6abec" alt="Deploy notes-dev release output" width="100%" />

---

## 4. Step 2: Verify Development Environment

Inspect the created pods, service, and rendered HTML page:
```bash
# Check pod status (1 replica)
kubectl get pods -l app.kubernetes.io/instance=notes-dev

# Check service type (ClusterIP)
kubectl get service notes-dev-notes-chart

# Test local HTTP response
kubectl run curl-test --rm -i --tty --image=busybox:1.36 --restart=Never -- \
  wget -qO- http://notes-dev-notes-chart
```

Expected Terminal Output:
```text
NAME                                         READY   STATUS    RESTARTS   AGE
notes-dev-notes-chart-6db769b764-89p2k       1/1     Running   0          25s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
notes-dev-notes-chart   ClusterIP   10.106.18.90    <none>        80/TCP    25s

<!DOCTYPE html>
<html>
<head><title>SST Notes App - Development</title></head>
<body style="font-family: sans-serif; padding: 40px; background-color: #f4f6f8;">
  <h1>SST Notes Application</h1>
  <p>Environment: <strong>development</strong></p>
  <p>Release Revision: <strong>1</strong></p>
  <p>Version: <strong>1.0.0</strong></p>
</body>
</html>
```

<img src="https://github.com/user-attachments/assets/93cfce29-c6f7-4585-9b4e-07a07f371b9a" alt="Development environment verification" width="100%" />

---

## 5. Step 3: Deploy to Production Environment with Overrides

Deploy a separate release using `values-prod.yaml` in the same cluster:
```bash
helm install notes-prod ./notes-chart -f ./notes-chart/values-prod.yaml
```

Expected Terminal Output:
```text
NAME: notes-prod
LAST DEPLOYED: Wed Sep 30 11:52:45 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

<img src="https://github.com/user-attachments/assets/b556c4b8-02e9-4926-83ff-ce496159ef19" alt="Deploy notes-prod release output" width="100%" />

---

## 6. Step 4: Verify Production Environment

Verify 3 replicas and NodePort assignment:
```bash
# Check 3 running replicas
kubectl get pods -l app.kubernetes.io/instance=notes-prod

# Check NodePort 30090
kubectl get service notes-prod-notes-chart

# Inspect ConfigMap environment setting
kubectl get configmap notes-prod-notes-chart-config -o jsonpath='{.data.APP_ENV}' && echo ""
```

Expected Terminal Output:
```text
NAME                                          READY   STATUS    RESTARTS   AGE
notes-prod-notes-chart-57bfb7b99c-2k9lx       1/1     Running   0          35s
notes-prod-notes-chart-57bfb7b99c-7x9pw       1/1     Running   0          35s
notes-prod-notes-chart-57bfb7b99c-m912v       1/1     Running   0          35s

NAME                     TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
notes-prod-notes-chart   NodePort   10.109.45.118   <none>        80:30090/TCP   35s

production
```

<img src="https://github.com/user-attachments/assets/b99d82a8-dc82-4219-b1a4-3111530504a0" alt="Production environment verification" width="100%" />

---

## 7. Step 5: Production Rolling Upgrade & Rollback Test

Simulate an upgrade to version 1.1.0 with a configuration change:
```bash
helm upgrade notes-prod ./notes-chart -f ./notes-chart/values-prod.yaml \
  --set app.logLevel="warn" \
  --set replicaCount=4
```

Verify the revision list:
```bash
helm history notes-prod
```

Expected Terminal Output:
```text
REVISION  UPDATED                   STATUS      CHART              APP VERSION  DESCRIPTION
1         Wed Sep 30 11:52:45 2026  superseded  notes-chart-0.1.0  1.0.0        Install complete
2         Wed Sep 30 11:54:10 2026  deployed    notes-chart-0.1.0  1.0.0        Upgrade complete
```

<img src="https://github.com/user-attachments/assets/36e33bfd-0a73-4adf-8572-2af0487722c7" alt="Production release upgraded to revision 2" width="100%" />

Execute rollback back to Revision 1:
```bash
helm rollback notes-prod 1
helm history notes-prod
```

Expected Terminal Output:
```text
Rollback was a success! Happy Helming!

REVISION  UPDATED                   STATUS      CHART              APP VERSION  DESCRIPTION
1         Wed Sep 30 11:52:45 2026  superseded  notes-chart-0.1.0  1.0.0        Install complete
2         Wed Sep 30 11:54:10 2026  superseded  notes-chart-0.1.0  1.0.0        Upgrade complete
3         Wed Sep 30 11:55:30 2026  deployed    notes-chart-0.1.0  1.0.0        Rollback to 1
```

<img src="https://github.com/user-attachments/assets/ea922d37-3566-46df-9467-e7d54d010c48" alt="Production release rollback to revision 3" width="100%" />

---

## 8. Summary of Multi-Environment Differences

| Dimension | Development (`notes-dev`) | Production (`notes-prod`) |
| :--- | :--- | :--- |
| **Values Source** | `values.yaml` | `values-prod.yaml` |
| **Replica Count** | 1 | 3 (scaled to 4 during upgrade) |
| **Image Tag** | `1.24-alpine` | `1.27-alpine` |
| **Service Type** | `ClusterIP` | `NodePort` (Port 30090) |
| **CPU / RAM Limits** | 50m / 64Mi | 200m / 128Mi |
| **Environment Flag** | `development` | `production` |
