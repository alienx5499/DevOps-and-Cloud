# Kubernetes Storage, HPA & Probes: Persistent Volumes, Health Checks & Autoscaling

Practical lab implementation covering ephemeral volumes (emptyDir, hostPath), decoupled persistent storage (PV, PVC), dynamic volume provisioning (StorageClass), container health checks (startup, readiness, liveness probes), and automated elastic scaling (HPA).

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Architecture Overview

<img width="8192" height="1816" alt="Session 13 Kubernetes Storage, HPA and Probes Complete Architecture" src="https://github.com/user-attachments/assets/c14eebae-5ca0-4900-882a-976dfe8dfcbb" />

---

## Module Index & Task Breakdown

| Section | Topic | Core Concepts | Manifests & Scripts |
| :--- | :--- | :--- | :--- |
| **01. Node-Local Volumes** | [01-volumes/](./01-volumes/README.md) | `emptyDir` shared multi-container scratchpad, `hostPath` node filesystem mounting | `01-emptydir-pod.yaml`<br>`02-hostpath-pod.yaml` |
| **02. Persistent Storage** | [02-persistent-storage/](./02-persistent-storage/README.md) | Decoupled PV/PVC lifecycle (Provisioning, Binding, Using, Reclaiming: Retain/Delete) | `01-pv.yaml`<br>`02-pvc.yaml`<br>`03-pod-pvc.yaml` |
| **03. StorageClasses** | [03-storageclass/](./03-storageclass/README.md) | Dynamic volume provisioning, CSI drivers, `WaitForFirstConsumer` multi-AZ topology mode | `01-storageclass.yaml`<br>`02-dynamic-pvc.yaml` |
| **04. Autoscaling (HPA)** | [04-hpa/](./04-hpa/README.md) | Metrics Server integration, CPU target algorithms, scale-out stress testing, 5m cooldown | `01-deployment.yaml`<br>`02-service.yaml`<br>`03-hpa.yaml`<br>`load_generator.sh` |
| **05. Container Probes** | [05-probes/](./05-probes/README.md) | Startup probe boot protection, readiness probe endpoint gating, liveness self-healing | `01-startup-probe.yaml`<br>`02-readiness-probe.yaml`<br>`03-liveness-probe.yaml` |
| **06. Mini-Project** | [mini-project/](./mini-project/README.md) | Combined production deployment with dedicated namespace, 500Mi PVC, probes, and HPA | `namespace.yaml`<br>`pvc.yaml`<br>`deployment.yaml`<br>`service.yaml`<br>`hpa.yaml`<br>`load_generator.sh` |

---

## Directory Structure

```text
Kubernetes Storage, HPA & Probes/
|-- 01-volumes/
|   |-- 01-emptydir-pod.yaml
|   |-- 02-hostpath-pod.yaml
|   `-- README.md
|-- 02-persistent-storage/
|   |-- 01-pv.yaml
|   |-- 02-pvc.yaml
|   |-- 03-pod-pvc.yaml
|   `-- README.md
|-- 03-storageclass/
|   |-- 01-storageclass.yaml
|   |-- 02-dynamic-pvc.yaml
|   `-- README.md
|-- 04-hpa/
|   |-- 01-deployment.yaml
|   |-- 02-service.yaml
|   |-- 03-hpa.yaml
|   |-- load_generator.sh
|   `-- README.md
|-- 05-probes/
|   |-- 01-startup-probe.yaml
|   |-- 02-readiness-probe.yaml
|   |-- 03-liveness-probe.yaml
|   `-- README.md
|-- mini-project/
|   |-- namespace.yaml
|   |-- pvc.yaml
|   |-- deployment.yaml
|   |-- service.yaml
|   |-- hpa.yaml
|   |-- load_generator.sh
|   `-- README.md
`-- README.md
```

---

## Key Learnings & Practical Takeaways

1. **Volume Lifecycles:** An `emptyDir` is destroyed when its Pod is terminated. A `PersistentVolume` lives independently of any Pod or claim, preserving critical state across redeployments.
2. **Dynamic Provisioning:** Manual PV creation does not scale. Defining a `StorageClass` with `volumeBindingMode: WaitForFirstConsumer` ensures disks are provisioned on-demand in the exact availability zone where Pods land.
3. **Container Health Checking:** 
   - `startupProbe` prevents slow-starting applications from getting killed prematurely during startup.
   - `readinessProbe` stops user traffic from reaching pods that are still warming up or overloaded.
   - `livenessProbe` detects frozen or deadlocked application loops and restarts the container automatically.
4. **Horizontal Pod Autoscaling:** Autoscaling relies on the Kubernetes Metrics Server. Containers must declare `resources.requests.cpu`, otherwise the autoscaler cannot calculate usage percentages. The 5-minute cooldown window prevents flapping during variable traffic.
