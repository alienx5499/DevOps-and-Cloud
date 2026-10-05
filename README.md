# DevOps & Cloud Engineering

Practical implementations, configurations, and technical documentation across containerization, orchestration, automation, cloud infrastructure, and observability.

---

## Repository Index & Course Modules

| Module | Core Topics Covered | Documentation Link |
| :--- | :--- | :--- |
| **01. Linux Fundamentals** | Soft vs. Hard Links, `adduser` vs. `useradd`, `journalctl` & `systemd`, `iproute2` command reference | [Linux Fundamental/README.md](./Linux%20Fundamental/README.md) |
| **02. Shell Scripting** | Interactive `system_info.sh` system diagnostics script, automated health reporting | [Shell Scripting/README.md](./Shell%20Scripting/README.md) |
| **03. Networking** | 10 Diagnostic commands (`ping`, `traceroute`, `ss`, `netstat`, `nc`, `tcpdump`, `dig`, `curl`, `arp`, `systemctl`) | [Networking/README.md](./Networking/README.md) |
| **04. Git and GitHub** | `git commit -a -m` vs `-m` staging mechanics, automated cherry-pick workflow | [Git and GitHub/README.md](./Git%20and%20GitHub/README.md) |
| **05. Docker Fundamentals** | 6 Hello World web apps (`nodejs-app`, `python-app`, `java-app`, `Apache-app`, `React-app`, `nginx-app`) | [Docker Fundamentals/README.md](./Docker%20Fundamentals/README.md) |
| **06. Docker Images** | Multi-stage Docker builds, image size optimization, 3-stack container deployments | [Docker Images/README.md](./Docker%20Images/README.md) |
| **07. Docker Networking** | Multi-network container isolation, host network mode, bind mounts hot reloading, overlay VXLAN | [Docker Networking/README.md](./Docker%20Networking/README.md) |
| **08. Kubernetes Fundamentals** | Cluster architecture, Control Plane & Worker components, Minikube lifecycle & status inspection | [Kubernetes Fundamentals/README.md](./Kubernetes%20Fundamentals/README.md) |
| **09. Kubernetes Pods, ReplicaSets & Deployments** | Pod manifests, self-healing ReplicaSets, rolling update Deployments, rollbacks | [Kubernetes Pods, ReplicaSets & Deployments/README.md](./Kubernetes%20Pods%2C%20ReplicaSets%20%26%20Deployments/README.md) |
| **10. Kubernetes Networking & Services** | ClusterIP, NodePort, LoadBalancer, CoreDNS discovery, kube-proxy routing | [Kubernetes Networking & Services/README.md](./Kubernetes%20Networking%20%26%20Services/README.md) |
| **11. Kubernetes Ingress, ConfigMaps & Secrets** | Ingress L7 routing, ConfigMap decoupled configurations, Base64 Secrets storage | [Kubernetes Ingress, ConfigMaps & Secrets/README.md](./Kubernetes%20Ingress%2C%20ConfigMaps%20%26%20Secrets/README.md) |
| **12. Kubernetes Storage, HPA & Probes** | `emptyDir`, `hostPath`, PV, PVC, StorageClass dynamic provisioning, HPA autoscaling, health probes | [Kubernetes Storage, HPA & Probes/README.md](./Kubernetes%20Storage%2C%20HPA%20%26%20Probes/README.md) |
| **13. Kubernetes Troubleshooting** | Pod lifecycle failures, `CrashLoopBackOff`, `ImagePullBackOff`, `Pending`, Service & DNS debug | [Kubernetes Troubleshooting/README.md](./Kubernetes%20Troubleshooting/README.md) |
| **14. Helm Package Manager** | Helm CLI lifecycle, chart templating, revision rollbacks, multi-environment deployments | [Helm/README.md](./Helm/README.md) |
| **15. CI/CD & GitHub Actions** | GitHub Actions workflows, jobs, runners, secrets, Cargo automated testing, build artifacts | [CI-CD & GitHub Actions/README.md](./CI-CD%20&%20GitHub%20Actions/README.md) |
| **16. Complete CI/CD & DevSecOps** | Security pipeline: Clippy SAST, cargo audit SCA, secret audit, Trivy image scanning, K8s rollout | [DevSecOps/README.md](./DevSecOps/README.md) |
| **17. Terraform & Infrastructure as Code** | S3 bucket declarative lifecycle, AWS services research (IAM, EC2, S3, VPC, DynamoDB & RDS) | [Terraform & Infrastructure as Code/README.md](./Terraform%20&%20Infrastructure%20as%20Code/README.md) |
| **18. Cloud & Terraform in Action** | End-to-end AWS cloud architecture: Custom VPC, Subnets, IGW, Security Groups, EC2 Nginx & S3 | [Cloud & Terraform in Action/README.md](./Cloud%20&%20Terraform%20in%20Action/README.md) |
| **19. Monitoring, Observability & GitOps** | Metrics, Logs, Traces (3 Pillars), Prometheus/Grafana stack, SLO alerts, ArgoCD continuous reconciliation | [Monitoring, Observability & GitOps/README.md](./Monitoring%2C%20Observability%20&%20GitOps/README.md) |
| **20. Final DevOps Project & Troubleshooting (Capstone)** | Full-stack TaskBoard SaaS: FastAPI, React + Vite, PostgreSQL 16, Docker Compose, K8s, Helm, DevSecOps, AWS Terraform | [Final DevOps Project & Troubleshooting/README.md](./Final%20DevOps%20Project%20&%20Troubleshooting/README.md) |

---

## Directory Structure

```text
.
├── Linux Fundamental/
│   ├── 01_Soft_vs_Hard_Links.md
│   ├── 02_adduser_vs_useradd.md
│   ├── 03_journalctl_Guide.md
│   ├── 04_Linux_Command_Cheat_Sheet.md
│   └── README.md
├── Shell Scripting/
│   ├── system_info.sh
│   └── README.md
├── Networking/
│   └── README.md
├── Git and GitHub/
│   └── README.md
├── Docker Fundamentals/
│   ├── nodejs-app/
│   ├── python-app/
│   ├── java-app/
│   ├── Apache-app/
│   ├── React-app/
│   ├── nginx-app/
│   └── README.md
├── Docker Images/
│   ├── multi-stage-app/
│   └── README.md
├── Docker Networking/
│   ├── html-bind/
│   └── README.md
├── Kubernetes Fundamentals/
│   └── README.md
├── Kubernetes Pods, ReplicaSets & Deployments/
│   └── README.md
├── Kubernetes Networking & Services/
│   └── README.md
├── Kubernetes Ingress, ConfigMaps & Secrets/
│   └── README.md
├── Kubernetes Storage, HPA & Probes/
│   ├── 01-volumes/
│   ├── 02-persistent-storage/
│   ├── 03-storageclass/
│   ├── 04-hpa/
│   ├── 05-probes/
│   ├── mini-project/
│   └── README.md
├── Kubernetes Troubleshooting/
│   ├── 01-kubectl-commands/
│   ├── 02-troubleshoot-issues/
│   ├── mini-project/
│   └── README.md
├── Helm/
│   ├── 01-helm-commands/
│   ├── 02-helm-rollback/
│   ├── mini-project/
│   └── README.md
├── CI-CD & GitHub Actions/
│   ├── Cargo.toml
│   ├── src/
│   ├── tests/
│   ├── .github/workflows/
│   ├── Dockerfile
│   └── README.md
├── DevSecOps/
│   ├── Cargo.toml
│   ├── src/
│   ├── tests/
│   ├── k8s/
│   ├── .github/workflows/
│   ├── Dockerfile
│   └── README.md
├── Terraform & Infrastructure as Code/
│   ├── terraform-s3-demo/
│   ├── aws-services/
│   │   ├── 01-iam/
│   │   ├── 02-ec2/
│   │   ├── 03-s3/
│   │   ├── 04-vpc/
│   │   └── 05-dynamodb-rds/
│   └── README.md
├── Cloud & Terraform in Action/
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── README.md
├── Monitoring, Observability & GitOps/
│   ├── app/
│   │   ├── Cargo.toml
│   │   └── src/
│   ├── k8s/
│   │   ├── 01-prometheus.yaml
│   │   ├── 02-grafana.yaml
│   │   ├── 03-alert-rules.yaml
│   │   └── 04-argocd-app.yaml
│   └── README.md
└── Final DevOps Project & Troubleshooting/
    ├── backend/              # FastAPI REST API, Alembic migrations, Pytest
    ├── frontend/             # React + Vite SaaS TaskBoard interface
    ├── docker-compose.yml    # Full-stack local multi-container orchestration
    ├── k8s/                  # Kubernetes manifests (deployments, services, HPA, ingress)
    ├── helm/                 # Helm chart for production packaging
    ├── terraform/            # Declarative AWS VPC & EKS cluster infrastructure
    ├── monitoring/           # Prometheus metrics & Grafana dashboards
    ├── troubleshooting/      # Root Cause Analysis (RCA) real-world scenarios
    ├── .github/workflows/    # CI/CD pipeline (lint, test, build, Trivy scan)
    ├── GRADING.md            # Course rubric & submission checklist
    ├── STUDENT-GUIDE.md      # Comprehensive student execution guide
    └── README.md             # Complete capstone documentation & verification proof
```

