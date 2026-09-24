# Helm Package Manager: Templating, Multi-Environment Releases & Rollbacks

Hands-on laboratory covering the Kubernetes Helm package manager, parameterized Go templates, value hierarchies, release revision tracking, and automated rollbacks.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Architecture: Helm Release Management

<img width="5717" height="3565" alt="Helm Architecture & Release Management" src="https://github.com/user-attachments/assets/71fb338b-b789-40c4-95e7-5f110a5f93d5" />

---

## Laboratory Structure & Navigation

| Directory | Task Focus | Key Helm Concepts & Commands |
| :--- | :--- | :--- |
| [01-helm-commands/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Helm/01-helm-commands/README.md) | Task 1: CLI Lifecycle | `helm create`, `install`, `list`, `status`, `get`, `upgrade`, `history`, `rollback`, `uninstall`, `repo`, `search` |
| [02-helm-rollback/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Helm/02-helm-rollback/README.md) | Task 2: Revision Rollback | Complete state progression: Install -> Upgrade -> Verify -> Upgrade again -> Verify -> Rollback -> Verify |
| [mini-project/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Helm/mini-project/README.md) | Task 3: Mini-Project | `notes-chart` with multi-environment overrides (`values.yaml` dev vs `values-prod.yaml` prod), configmap injection |

---

## Key Takeaways

1. **Templating removes repetition:** Instead of maintaining duplicate YAML sets for dev, staging, and production, a single chart with environment-specific values files handles all deployments.
2. **Release tracking is native:** Helm records each deployment in Kubernetes Secrets. Revisions are immutable, and rolling back is a single CLI command without changing source YAML.
3. **Deterministic rollouts:** By combining Helm upgrades with Kubernetes rolling update strategies, application updates can be tested, observed, and rolled back safely.
