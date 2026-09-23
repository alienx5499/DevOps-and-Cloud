# Task 1: Essential Helm CLI Commands

Complete practical reference for managing Kubernetes applications using the Helm package manager. Covers chart creation, release installation, configuration inspection, revision lifecycle management, and repository discovery.

---

## 1. Helm Lifecycle Flow

Helm treats a collection of Kubernetes manifests as a single managed application release:

<img width="7560" height="830" alt="Helm Lifecycle Flow" src="https://github.com/user-attachments/assets/87c998f0-f8de-44c7-9aa8-1a65c63c37bf" />

---

## 2. Command Reference & Hands-on Verification

---

### 2.1 helm create

Generates a new directory containing the standard directory layout for a Helm chart: `Chart.yaml`, `values.yaml`, `.helmignore`, and `templates/`.

```bash
helm create my-scaffold-chart
ls -la my-scaffold-chart
```

Expected Terminal Output:
```text
Creating my-scaffold-chart
total 16
drwxr-xr-x   7 user  staff   224 Sep 30 11:30 .
drwxr-xr-x   3 user  staff    96 Sep 30 11:30 ..
-rw-r--r--   1 user  staff   354 Sep 30 11:30 .helmignore
-rw-r--r--   1 user  staff  1152 Sep 30 11:30 Chart.yaml
drwxr-xr-x   8 user  staff   256 Sep 30 11:30 charts
drwxr-xr-x  10 user  staff   320 Sep 30 11:30 templates
-rw-r--r--   1 user  staff  1900 Sep 30 11:30 values.yaml
```

<img src="https://github.com/user-attachments/assets/3e87ccc3-9536-468a-91fc-40b1c57b9711" alt="helm create output" width="100%" />

---

### 2.2 helm install

Renders the templates within the specified chart and creates the Kubernetes resources in the target cluster, establishing Release Revision 1.

```bash
helm install demo-release ./app-chart
```

Expected Terminal Output:
```text
NAME: demo-release
LAST DEPLOYED: Wed Sep 30 11:32:15 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

<img src="https://github.com/user-attachments/assets/73681648-62e9-4e8b-b656-8ab2402918c5" alt="helm install output" width="100%" />

---

### 2.3 helm list

Lists all releases currently deployed in the target namespace (or all namespaces with `-A`).

```bash
helm list
```

Expected Terminal Output:
```text
NAME            NAMESPACE  REVISION  UPDATED                                 STATUS    CHART            APP VERSION
demo-release    default    1         2026-09-30 11:32:15.120341 +0000 UTC     deployed  app-chart-0.1.0  1.27.0
```

<img src="https://github.com/user-attachments/assets/c00ab877-8a5d-4fc5-b1d4-c0c4a39536db" alt="helm list output" width="100%" />

---

### 2.4 helm status

Displays runtime details, status, and rendered manifest summary for a specific named release.

```bash
helm status demo-release
```

Expected Terminal Output:
```text
NAME: demo-release
LAST DEPLOYED: Wed Sep 30 11:32:15 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
RESOURCES:
==> v1/Deployment
NAME                     READY  UP-TO-DATE  AVAILABLE  AGE
demo-release-deployment  2/2    2           2          45s

==> v1/Service
NAME                  TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
demo-release-service  ClusterIP  10.102.140.210  <none>       80/TCP   45s
```

<img src="https://github.com/user-attachments/assets/6de75ea0-6db1-40d4-8d7b-92bbdc8d40d7" alt="helm status output" width="100%" />

---

### 2.5 helm get (values, manifest, all)

Extracts deployed information directly from the cluster storage backend (stored as Kubernetes Secrets).

```bash
# Retrieve user-supplied override values
helm get values demo-release

# Retrieve the complete generated Kubernetes YAML manifest
helm get manifest demo-release | grep -E "(kind:|name:)"

# Retrieve all metadata, hooks, and notes
helm get all demo-release
```

Expected Terminal Output:
```text
USER-SUPPLIED VALUES:
null

kind: Deployment
  name: demo-release-deployment
kind: Service
  name: demo-release-service
```

<img src="https://github.com/user-attachments/assets/2badbdd9-18da-447c-a570-40f0dd5a9faf" alt="helm get output" width="100%" />

---

### 2.6 helm upgrade

Updates an existing release by applying new value overrides, upgrading chart versions, or modifying templates. Creates a new revision record.

```bash
# Scale replicas to 4 and override image tag to 1.27.0-alpine
helm upgrade demo-release ./app-chart --set replicaCount=4 --set image.tag="1.27.0-alpine"
```

Expected Terminal Output:
```text
Release "demo-release" has been upgraded. Happy Helming!
NAME: demo-release
LAST DEPLOYED: Wed Sep 30 11:35:02 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

<img src="https://github.com/user-attachments/assets/c9354acb-2035-4741-800e-d22731f551ba" alt="helm upgrade output" width="100%" />

---

### 2.7 helm history

Displays the chronological revision audit log for the release, showing chart version, app version, and description for every change.

```bash
helm history demo-release
```

Expected Terminal Output:
```text
REVISION  UPDATED                   STATUS      CHART            APP VERSION  DESCRIPTION
1         Wed Sep 30 11:32:15 2026  superseded  app-chart-0.1.0  1.27.0       Install complete
2         Wed Sep 30 11:35:02 2026  deployed    app-chart-0.1.0  1.27.0       Upgrade complete
```

<img src="https://github.com/user-attachments/assets/826e8499-1ac2-42a1-b529-dcc3a7487c34" alt="helm history output" width="100%" />

---

### 2.8 helm rollback

Rolls back the release to a previously deployed revision number. This creates a new revision matching the target revision state without manual YAML modifications.

```bash
# Rollback from revision 2 back to revision 1
helm rollback demo-release 1
```

Expected Terminal Output:
```text
Rollback was a success! Happy Helming!
```

Verify history reflects the rollback:
```bash
helm history demo-release
```

Terminal Output:
```text
REVISION  UPDATED                   STATUS      CHART            APP VERSION  DESCRIPTION
1         Wed Sep 30 11:32:15 2026  superseded  app-chart-0.1.0  1.27.0       Install complete
2         Wed Sep 30 11:35:02 2026  superseded  app-chart-0.1.0  1.27.0       Upgrade complete
3         Wed Sep 30 11:37:18 2026  deployed    app-chart-0.1.0  1.27.0       Rollback to 1
```

<img src="https://github.com/user-attachments/assets/7741c8d7-d545-40fa-a28e-7f2b8e2cbf59" alt="helm rollback output" width="100%" />

---

### 2.9 helm repo (add, update, list)

Manages remote chart repository connections.

```bash
# Add official Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update local cache with remote index metadata
helm repo update

# List configured repositories
helm repo list
```

Expected Terminal Output:
```text
"bitnami" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. Happy Helming!

NAME     URL
bitnami  https://charts.bitnami.com/bitnami
```

<img src="https://github.com/user-attachments/assets/9ca965cb-bca5-415f-bc79-e2a7797a8a9d" alt="helm repo output" width="100%" />

---

### 2.10 helm search (repo, hub)

Searches for packaged charts in local repositories or the global Artifact Hub registry.

```bash
# Search configured local repositories for nginx
helm search repo nginx

# Search public Artifact Hub
helm search hub prometheus | head -n 5
```

Expected Terminal Output:
```text
NAME            CHART VERSION  APP VERSION  DESCRIPTION
bitnami/nginx   18.2.1         1.27.1       NGINX Open Source is a web server that can a...

URL                                                     CHART VERSION  APP VERSION  DESCRIPTION
https://artifacthub.io/packages/helm/prometheus-comm... 25.27.0        v2.54.1      Prometheus is a monitoring system and time s...
```

<img src="https://github.com/user-attachments/assets/df2c45ab-acf6-4bfd-bbf2-af54a88e7084" alt="helm search output" width="100%" />

---

### 2.11 helm uninstall

Deletes the release from the cluster, removing all associated deployments, services, pods, and release metadata.

```bash
helm uninstall demo-release
```

Expected Terminal Output:
```text
release "demo-release" uninstalled
```

<img src="https://github.com/user-attachments/assets/323d75d7-6f78-425c-8353-1e871bbc34d7" alt="helm uninstall output" width="100%" />

---

## 3. Command Summary Table

| Command | Primary Function | Example Syntax |
| :--- | :--- | :--- |
| `helm create` | Scaffolds directory layout | `helm create my-chart` |
| `helm install` | Deploys chart to cluster | `helm install web ./my-chart` |
| `helm list` | Shows deployed releases | `helm list -A` |
| `helm status` | Inspects live release state | `helm status web` |
| `helm get values` | Inspects user value overrides | `helm get values web` |
| `helm upgrade` | Updates running release | `helm upgrade web ./my-chart --set replicas=3` |
| `helm history` | Shows release revisions | `helm history web` |
| `helm rollback` | Reverts to prior revision | `helm rollback web 1` |
| `helm repo add` | Adds remote chart source | `helm repo add bitnami <url>` |
| `helm search` | Searches chart indexes | `helm search repo nginx` |
| `helm uninstall` | Deletes release & objects | `helm uninstall web` |
