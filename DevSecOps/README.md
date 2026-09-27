# Session 17: Complete CI/CD & DevSecOps Pipeline

Implementation of an automated DevSecOps delivery pipeline combining unit testing (`pytest`), Static Application Security Testing (`bandit`), Software Composition Analysis (`pip-audit`), secret leak detection, container image vulnerability scanning (`trivy`), security quality gates, and Kubernetes deployment manifests.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## 1. DevSecOps Architecture & Workflow

<img width="5717" height="3565" alt="DevSecOps Architecture and Pipeline Workflow" src="https://github.com/user-attachments/assets/71fb338b-b789-40c4-95e7-5f110a5f93d5" />

---

## 2. Core DevSecOps Pillars

### 2.1 Static Application Security Testing (SAST)
Analyzes source code without running it. Bandit inspects Python Abstract Syntax Trees (AST) to identify security risks such as hardcoded passwords, insecure function calls, debug configurations left enabled in production, and weak random number generators.

### 2.2 Software Composition Analysis (SCA)
Scans direct and transitive dependencies defined in `requirements.txt`. `pip-audit` cross-checks installed package versions against known vulnerabilities in the Open Source Vulnerabilities (OSV) database and PyPI advisories.

### 2.3 Secret Scanning
Scans the source tree and commit history to prevent credentials, private keys (`.pem`, `.key`), cloud access tokens (`AKIA...`), and GitHub Personal Access Tokens (`ghp_...`) from being committed or pushed to remote repositories.

### 2.4 Container Image Scanning
Inspects the built container image layers. Trivy checks both the underlying Alpine Linux OS packages and Python wheel dependencies for unpatched CVEs.

### 2.5 Security Quality Gates
Enforces build failure when critical or high security issues are discovered. If any stage finds unresolved vulnerabilities above the acceptable threshold, the workflow halts before deploying to Kubernetes.

---

## 3. Local Execution & Step-by-Step Verification

### 3.1 Step 1: Run Unit Tests with Pytest
Run the test suite verifying Flask API routes, parameter handling, and status checks:

```bash
pytest -v tests/test_app.py
```

<img width="1928" height="540" alt="01-pytest-unit-tests" src="https://github.com/user-attachments/assets/d6834095-2efb-4e1d-a442-607bffe06e97" />

Expected Terminal Output:
```text
============================= test session starts ==============================
platform darwin -- Python 3.12.9, pytest-9.1.1, pluggy-1.6.0
rootdir: /Developer/SST/SST Term 9/DevOps & Cloud [SWE]/DevSecOps
configfile: pytest.ini
plugins: cov-7.1.0, platformdirs-4.12.3
collected 8 items

tests/test_app.py::test_home PASSED                                      [ 12%]
tests/test_app.py::test_health PASSED                                    [ 25%]
tests/test_app.py::test_greet PASSED                                     [ 37%]
tests/test_app.py::test_add_numbers PASSED                               [ 50%]
tests/test_app.py::test_add_numbers_missing_fields PASSED                [ 62%]
tests/test_app.py::test_calculator_multiply PASSED                       [ 75%]
tests/test_app.py::test_calculator_divide_by_zero PASSED                 [ 87%]
tests/test_app.py::test_status PASSED                                    [100%]

============================== 8 passed in 0.07s ===============================
```

---

### 3.2 Step 2: Static Application Security Testing (SAST) with Bandit
Run static security analysis on the application source code:

```bash
bandit -r app/ -ll
```

<img width="1414" height="756" alt="02-sast-bandit" src="https://github.com/user-attachments/assets/42db2061-46ee-4266-8a42-6c3382058a22" />

Expected Terminal Output:
```text
[main]	INFO	profile include tests: None
[main]	INFO	profile exclude tests: None
[main]	INFO	cli include tests: None
[main]	INFO	cli exclude tests: None
[main]	INFO	running on Python 3.12.9
Run started:2026-10-07 18:16:58.243512

Test results:
	No issues identified.

Code scanned:
	Total lines of code: 62
	Total lines skipped (#nosec): 0

Run metrics:
	Total issues (by severity):
		Undefined: 0
		Low: 0
		Medium: 0
		High: 0
	Total issues (by confidence):
		Undefined: 0
		Low: 0
		Medium: 0
		High: 0
Files skipped (0):
```

---

### 3.3 Step 3: Software Composition Analysis (SCA) with pip-audit
Check third-party packages in `requirements.txt` for known vulnerabilities:

```bash
pip-audit -r requirements.txt
```

<img width="2924" height="66" alt="03-sca-pip-audit" src="https://github.com/user-attachments/assets/53fc4837-9974-4127-a7c7-f8b209ae0639" />

Expected Terminal Output:
```text
No known vulnerabilities found
```

---

### 3.4 Step 4: Secret Scanning Verification
Scan the repository files for exposed credentials or private keys:

```bash
if grep -r -E "(BEGIN (RSA |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[0-9a-zA-Z]{36})" . \
  --exclude-dir={.git,.pytest_cache} ; then
  echo "Security Alert: Leaked secret detected!"
  exit 1
else
  echo "Clean: Zero hardcoded secrets identified."
fi
```

<img width="2932" height="88" alt="04-secret-scanning" src="https://github.com/user-attachments/assets/6cf70ad2-f71c-46d9-8932-a9b4b6a14a0c" />

Expected Terminal Output:
```text
Clean: Zero hardcoded secrets identified.
```

---

### 3.5 Step 5: Container Build & Trivy Vulnerability Scan
Build the hardened Alpine container image and scan it for high and critical CVEs:

```bash
docker build -t session17-python:latest .
trivy image --severity HIGH,CRITICAL session17-python:latest
```

<img width="3022" height="1730" alt="05-docker-build-and-trivy" src="https://github.com/user-attachments/assets/05c356f5-e37b-4439-9096-61aab0a29c1b" />

Expected Terminal Output:
```text
[+] Building 0.4s (10/10) FINISHED
 => [internal] load build definition from Dockerfile
 => [1/5] FROM docker.io/library/python:3.12-alpine
 => CACHED [2/5] WORKDIR /app
 => CACHED [3/5] COPY requirements.txt .
 => CACHED [4/5] RUN pip install --no-cache-dir -r requirements.txt
 => CACHED [5/5] COPY app ./app
 => naming to docker.io/library/session17-python:latest

Report Summary

┌──────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                                    Target                                    │    Type    │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ session17-python:latest (alpine 3.24.2)                                      │   alpine   │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/blinker-1.9.0.dist-info/METADATA      │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/click-8.5.0.dist-info/METADATA        │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/flask-3.1.3.dist-info/METADATA        │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/itsdangerous-2.2.0.dist-info/METADATA │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/jinja2-3.1.6.dist-info/METADATA       │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/markupsafe-3.0.4.dist-info/METADATA   │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/pip-25.0.1.dist-info/METADATA         │ python-pkg │        0        │    -    │
├──────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.12/site-packages/werkzeug-3.1.9.dist-info/METADATA     │ python-pkg │        0        │    -    │
└──────────────────────────────────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

---

### 3.6 Step 6: Kubernetes Deployment Manifests
Deploy the verified container into Kubernetes:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

The application runs two replicas with liveness and readiness probes pointing to `/api/health`.

---

## 4. Pipeline Summary Table

| Stage | Tool | Function | Pass Criteria |
| :--- | :--- | :--- | :--- |
| **Unit Testing** | `pytest` | Validates API routes and arithmetic functions | 100% tests pass |
| **SAST** | `bandit` | Static security analysis of Python code | 0 high/medium issues |
| **SCA** | `pip-audit` | Audits dependencies against PyPI/OSV advisories | 0 vulnerabilities found |
| **Secret Scanning** | Regex patterns | Checks for exposed credentials and private keys | 0 matches |
| **Container Build** | Docker | Packages Alpine base with non-root user | Successful build |
| **Container Scan** | Aqua Trivy | Scans OS and package layers for CVEs | 0 high/critical CVEs |
| **Deployment** | Kubernetes | Manages rolling deployments and health checks | All pods running |
