# Task 2: Helm Rollback Lifecycle & Revision History

Comprehensive hands-on guide covering automated release rollbacks, revision state tracking, zero-downtime recovery from bad deployments, and release history auditing.

---

## 1. Rollback Lifecycle Flowchart

<img width="8040" height="4225" alt="Rollback Lifecycle Flowchart" src="https://github.com/user-attachments/assets/2285f322-bc63-4b70-af07-427023ce9ad6" />

---

## 2. Step-by-Step Hands-on Workflow

We use the chart from `01-helm-commands/app-chart` to simulate the full lifecycle.

---

### Step 1: Install Initial Working Version (Revision 1)

Deploy release `rollback-demo` with verified stable settings:
```bash
helm install rollback-demo ../01-helm-commands/app-chart \
  --set replicaCount=2 \
  --set image.tag="1.27-alpine"
```

Expected Terminal Output:
```text
NAME: rollback-demo
LAST DEPLOYED: Wed Sep 30 11:42:01 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

<img src="https://github.com/user-attachments/assets/4f79f3b0-dcfd-4cf3-8b09-8640d8e5529c" alt="Initial Helm install Revision 1 output" width="100%" />

---

### Step 2: Verify Revision 1 Health

Check pods and release history:
```bash
kubectl get pods -l app.kubernetes.io/instance=rollback-demo
helm history rollback-demo
```

Expected Terminal Output:
```text
NAME                                      READY   STATUS    RESTARTS   AGE
rollback-demo-deployment-74f9d8544-6g8kl   1/1     Running   0          25s
rollback-demo-deployment-74f9d8544-p9x2w   1/1     Running   0          25s

REVISION  UPDATED                   STATUS    CHART            APP VERSION  DESCRIPTION
1         Wed Sep 30 11:42:01 2026  deployed  app-chart-0.1.0  1.27.0       Install complete
```

<img src="https://github.com/user-attachments/assets/acd56960-413e-4727-9096-ba0dea7218aa" alt="Revision 1 healthy pods verification" width="100%" />

---

### Step 3: Upgrade to Broken Version (Revision 2)

Simulate a broken deployment caused by an invalid image tag:
```bash
helm upgrade rollback-demo ../01-helm-commands/app-chart \
  --set replicaCount=2 \
  --set image.tag="invalid-image-does-not-exist"
```

Expected Terminal Output:
```text
Release "rollback-demo" has been upgraded. Happy Helming!
NAME: rollback-demo
LAST DEPLOYED: Wed Sep 30 11:43:20 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

<img src="https://github.com/user-attachments/assets/f874ac4a-db0d-426c-aff0-4aeb5cfb73c1" alt="Upgrade to broken Revision 2 output" width="100%" />

---

### Step 4: Verify Failure on Revision 2

Inspect pod status to observe the deployment failure:
```bash
kubectl get pods -l app.kubernetes.io/instance=rollback-demo
kubectl describe pod -l app.kubernetes.io/instance=rollback-demo | grep -A 3 "Events:"
```

Expected Terminal Output:
```text
NAME                                      READY   STATUS             RESTARTS   AGE
rollback-demo-deployment-559d89b65-2kx7p   0/1     ImagePullBackOff   0          30s
rollback-demo-deployment-74f9d8544-6g8kl   1/1     Running            0          90s
rollback-demo-deployment-74f9d8544-p9x2w   1/1     Running            0          90s

Events:
  Warning  Failed   15s (x2 over 28s)  kubelet  Failed to pull image "nginx:invalid-image-does-not-exist": rpc error: code = NotFound
  Warning  Failed   15s (x2 over 28s)  kubelet  Error: ErrImagePull
```

<img src="https://github.com/user-attachments/assets/f1456ce8-4a75-461e-9c95-feddbcfcdcac" alt="Revision 2 ImagePullBackOff failure" width="100%" />

---

### Step 5: Upgrade Again (Revision 3)

Simulate an attempted configuration update that changes replica count to 3 but still fails:
```bash
helm upgrade rollback-demo ../01-helm-commands/app-chart \
  --set replicaCount=3 \
  --set image.tag="still-broken-tag-v99"
```

Expected Terminal Output:
```text
Release "rollback-demo" has been upgraded. Happy Helming!
NAME: rollback-demo
LAST DEPLOYED: Wed Sep 30 11:44:55 2026
NAMESPACE: default
STATUS: deployed
REVISION: 3
TEST SUITE: None
```

<img src="https://github.com/user-attachments/assets/ce501d8e-69d5-4218-a97f-13a23e03cf09" alt="Upgrade to Revision 3 output" width="100%" />

---

### Step 6: Verify Revision 3 Status & History

Check the release audit trail showing revisions 1, 2, and 3:
```bash
helm history rollback-demo
```

Expected Terminal Output:
```text
REVISION  UPDATED                   STATUS      CHART            APP VERSION  DESCRIPTION
1         Wed Sep 30 11:42:01 2026  superseded  app-chart-0.1.0  1.27.0       Install complete
2         Wed Sep 30 11:43:20 2026  superseded  app-chart-0.1.0  1.27.0       Upgrade complete
3         Wed Sep 30 11:44:55 2026  deployed    app-chart-0.1.0  1.27.0       Upgrade complete
```

<img src="https://github.com/user-attachments/assets/ac9b4cc8-f78f-4ec9-8916-3b1958bc6a62" alt="Helm history showing revisions 1 2 and 3" width="100%" />

---

### Step 7: Rollback to Known Good Revision (Revision 1)

Execute the rollback directly to Revision 1 without modifying YAML files:
```bash
helm rollback rollback-demo 1
```

Expected Terminal Output:
```text
Rollback was a success! Happy Helming!
```

<img src="https://github.com/user-attachments/assets/aacd2ad9-c69c-4a2f-b2f8-ef6cf79af029" alt="Helm rollback execution output" width="100%" />

---

### Step 8: Verify Complete Recovery

Verify that the cluster terminates the broken pods and stabilizes on Revision 1 configuration:
```bash
# Check pod health
kubectl get pods -l app.kubernetes.io/instance=rollback-demo

# Check release history
helm history rollback-demo

# Verify active container image is 1.27-alpine
kubectl get deployment rollback-demo-deployment -o jsonpath='{.spec.template.spec.containers[0].image}' && echo ""
```

Expected Terminal Output:
```text
NAME                                      READY   STATUS    RESTARTS   AGE
rollback-demo-deployment-74f9d8544-6g8kl   1/1     Running   0          4m
rollback-demo-deployment-74f9d8544-p9x2w   1/1     Running   0          4m

REVISION  UPDATED                   STATUS      CHART            APP VERSION  DESCRIPTION
1         Wed Sep 30 11:42:01 2026  superseded  app-chart-0.1.0  1.27.0       Install complete
2         Wed Sep 30 11:43:20 2026  superseded  app-chart-0.1.0  1.27.0       Upgrade complete
3         Wed Sep 30 11:44:55 2026  superseded  app-chart-0.1.0  1.27.0       Upgrade complete
4         Wed Sep 30 11:46:12 2026  deployed    app-chart-0.1.0  1.27.0       Rollback to 1

nginx:1.27-alpine
```

<img src="https://github.com/user-attachments/assets/cfdb7e56-5464-43f0-8370-a4ed69bccd6a" alt="Complete recovery and revision 4 verified" width="100%" />

---

## 3. Key Takeaways

1. **Rollback creates a new revision:** Rollback does not erase history. Rolling back to Revision 1 records Revision 4 with description `Rollback to 1`. This preserves an immutable audit log.
2. **Atomic rollback protects traffic:** If an upgrade fails to progress, Kubernetes rolling update mechanics prevent traffic interruption while Helm allows instant recovery.
3. **Storage backend:** Helm stores revision manifests as base64-encoded, gzip-compressed Kubernetes Secrets in the target namespace (e.g. `sh.helm.release.v1.rollback-demo.v1`).
