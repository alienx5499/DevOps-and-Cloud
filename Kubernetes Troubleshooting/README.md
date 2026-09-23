# Kubernetes Troubleshooting: Pod Lifecycle, Health Failures & Service Diagnostics

Structured hands-on laboratory covering systematic Kubernetes diagnostics, CLI inspection workflows, common container failure modes, and Service endpoint resolution.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## The Golden Troubleshooting Flowchart

When an application fails in Kubernetes, avoid random modifications. Follow this structured diagnostic sequence:

<img width="7059" height="4840" alt="Golden Troubleshooting Flowchart" src="https://github.com/user-attachments/assets/f1934e0d-bf18-45ef-aae7-f65854e92946" />

---

## Laboratory Structure & Navigation

| Directory | Task Focus | Key Kubernetes Concepts & Commands |
| :--- | :--- | :--- |
| [01-kubectl-commands/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Kubernetes%20Troubleshooting/01-kubectl-commands/README.md) | Task 1: CLI Inspection | `kubectl get`, `describe`, `logs`, `exec`, `get events`, `explain`, `top`, `get -o wide` |
| [02-troubleshoot-issues/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Kubernetes%20Troubleshooting/02-troubleshoot-issues/README.md) | Task 2: Failure Patterns | `CrashLoopBackOff`, `ImagePullBackOff`, `Pending`, `ContainerCreating`, Service & DNS debug |
| [mini-project/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Kubernetes%20Troubleshooting/mini-project/README.md) | Task 3: Hands-on Challenge | Multi-tier app debug, broken pod diagnosis, service selector mismatch repair, questionnaire |

---

## Key Takeaways

1. **Events provide the timeline:** The `Events` table at the bottom of `kubectl describe` explains what the scheduler and kubelet attempted before failing.
2. **Logs capture runtime errors:** Application crashes produce stack traces on stdout/stderr. Use `--previous` to see logs from containers that restarted.
3. **Endpoints bridge Services and Pods:** If a Service cannot reach its pods, check `kubectl get endpoints <service>`. An empty endpoint list indicates a label/selector mismatch.
