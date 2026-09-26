# Session 16: CI/CD & GitHub Actions Automation

Implementation of an automated Continuous Integration and Continuous Delivery pipeline using GitHub Actions, Python toolchain verification (`pytest`), build artifact archiving, repository secret scanning, and Docker containerization.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## 1. CI vs CD Pipelines

Continuous Integration (CI) and Continuous Delivery (CD) cover two different stages of an automated software delivery pipeline:

<img width="8192" height="1331" alt="CI vs CD Delivery Pipeline Flow" src="https://github.com/user-attachments/assets/cba4020f-af6e-42cd-bfb7-bccdfb651d54" />

| Dimension | Continuous Integration (CI) | Continuous Delivery (CD) | Continuous Deployment |
| :--- | :--- | :--- | :--- |
| **Primary Goal** | Validate code changes early | Package reliable releases | Automatically push to users |
| **Key Actions** | Linting, unit tests, build | Artifact creation, staging deploy | Production deployment |
| **Trigger** | Push or Pull Request | Merge to main branch | Successful CD pipeline |
| **Human Gate** | None (automated) | Manual approval for production | Zero manual gates |

---

## 2. GitHub Actions Core Concepts

GitHub Actions provides an event-driven automation platform built directly into GitHub repositories:

1. **Workflow:** An automated configurable process made up of one or more jobs, defined in YAML under `.github/workflows/`.
2. **Event:** A specific activity that triggers a workflow run (e.g. `push`, `pull_request`, `schedule`, or manual `workflow_dispatch`).
3. **Job:** A set of steps executed sequentially on the same runner virtual environment. By default, jobs run in parallel unless linked via `needs:`.
4. **Step:** An individual task that can run shell commands or execute an action from the GitHub Marketplace.
5. **Runner:** A virtual machine hosted by GitHub (`ubuntu-latest`, `windows-latest`, `macos-latest`) or self-hosted in your infrastructure.
6. **Secrets:** Encrypted environment variables configured in repository settings (`${{ secrets.SECRET_NAME }}`) shielded from log outputs.
7. **Artifacts:** Files or directories persisted after a workflow run finishes, allowing data sharing across jobs or manual download.

---

## 3. Pipeline Execution Flow

<img width="8191" height="2108" alt="GitHub Actions Pipeline Flowchart" src="https://github.com/user-attachments/assets/3e1db647-2d8d-4b4b-be58-f59ef4eba95c" />

---

## 4. Local Execution & Step-by-Step Verification

### 4.1 Step 1: Run Unit Tests with Pytest
Install dependencies and run the unit test suite:

```bash
pip install -r requirements.txt
pytest -v tests/test_calculator.py
```

<img width="3024" height="863" alt="01-pytest-unit-tests" src="https://github.com/user-attachments/assets/3eddd8a8-486f-42e9-a526-c3cdee63dd87" />

Expected Terminal Output:
```text
============================= test session starts ==============================
platform darwin -- Python 3.12.9, pytest-9.1.1, pluggy-1.6.0
rootdir: /Developer/SST/SST Term 9/DevOps & Cloud [SWE]/CI-CD & GitHub Actions
collected 5 items

tests/test_calculator.py::test_add PASSED                                [ 20%]
tests/test_calculator.py::test_subtract PASSED                           [ 40%]
tests/test_calculator.py::test_multiply PASSED                           [ 60%]
tests/test_calculator.py::test_divide PASSED                             [ 80%]
tests/test_calculator.py::test_divide_by_zero PASSED                      [100%]

============================== 5 passed in 0.01s ===============================
```

---

### 4.2 Step 2: Execute Local Build Script
Package the release artifact using the automated build script:

```bash
chmod +x build.sh
./build.sh
cat build/build-info.txt
```

<img width="3024" height="1116" alt="02-build-script-artifact" src="https://github.com/user-attachments/assets/a0630c0e-a605-4078-8960-19b744b8fae6" />

Expected Terminal Output:
```text
=================================
Starting Application Build
=================================

Build files:
total 16
drwxr-xr-x   4 prabalpatra  staff   128 Oct  7 22:51 .
drwxr-xr-x  12 prabalpatra  staff   384 Oct  7 22:51 ..
-rw-r--r--   1 prabalpatra  staff    98 Oct  7 22:51 build-info.txt
-rw-r--r--   1 prabalpatra  staff  1488 Oct  7 22:51 calculator.py

Build completed successfully.

Application: Session 16 Calculator
Build Status: SUCCESS
Build Date: Wed Oct  7 22:51:31 IST 2026
```

---

### 4.3 Step 3: Verify Sensitive File Security Check
Audit the working tree to ensure no uncommitted `.env`, `.pem`, or `.key` secret files are present:

```bash
if find . -type f \( -name ".env" -o -name "*.pem" -o -name "*.key" \) | grep -q .; then
  echo "Security Alert: Exposed sensitive file detected!"
  exit 1
else
  echo "Clean: No sensitive files located."
fi
```

<img width="3024" height="222" alt="03-sensitive-files-check" src="https://github.com/user-attachments/assets/cfc8221c-8700-41e3-860c-ffa7e6ce2356" />

Expected Terminal Output:
```text
Clean: No sensitive files located.
```

---

### 4.4 Step 4: Build and Test Docker Container
Build the lightweight Python container image and run arithmetic calculations inside the container:

```bash
docker build -t session16-calculator:latest .
echo -e "10 + 5\n6 * 7\nq" | docker run -i --rm session16-calculator:latest
```

<img width="3024" height="1626" alt="04-docker-build-and-run" src="https://github.com/user-attachments/assets/83828fb8-f45f-4e27-815d-f51c6a788790" />

Expected Terminal Output:
```text
[+] Building 10.2s (11/11) FINISHED
 => [internal] load build definition from Dockerfile
 => [1/5] FROM docker.io/library/python:3.12-alpine
 => [2/5] WORKDIR /app
 => [3/5] COPY requirements.txt .
 => [4/5] RUN pip install --no-cache-dir -r requirements.txt
 => [5/5] COPY app/ ./app/
 => naming to docker.io/library/session16-calculator:latest

Calculator Application
----------------------
Available operations: +, -, *, /
Type 'q' or 'quit' to exit.

Enter calculation (e.g., 10 + 5): Result: 15.0
Enter calculation (e.g., 10 + 5): Result: 42.0
Enter calculation (e.g., 10 + 5): Goodbye!
```

---

### 4.5 Step 5: Test Failure & Quality Gate Scenario
Demonstrate the automated quality gate by introducing a deliberate bug:

```python
# app/calculator.py
def add(a, b):
    return a + b + 1  # Bug introduced!
```

Running pytest:
```text
FAILED tests/test_calculator.py::test_add - assert 16 == 15
```

Because `build` specifies `needs: test`, the GitHub Actions runner **halts immediately**. The buggy package is never built and no Docker container is deployed. Once the function is corrected to `return a + b`, all 4 pipeline stages turn green.

---

## 5. Summary of Pipeline Components

| Component | Technology | Purpose in Pipeline |
| :--- | :--- | :--- |
| **Source Code** | Python 3.12 (`app/calculator.py`) | Arithmetic application logic and CLI entrypoint |
| **Unit Testing** | Pytest (`tests/test_calculator.py`) | Automated test execution on every commit / PR |
| **Packaging** | Bash (`build.sh`) | Bundles application and generates metadata manifest |
| **Artifacts** | `actions/upload-artifact@v4` | Archives the `build/` directory for release download |
| **Security Gate** | Shell secret scanner | Blocks commits containing API keys, certificates, or `.env` files |
| **Container Engine** | Docker (`python:3.12-alpine`) | Generates a 58MB minimal production container |

---

## 6. Directory Structure

```text
CI-CD & GitHub Actions/
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI/CD pipeline
├── .gitignore                   # Ignore build artifacts and cache
├── Dockerfile                   # Python 3.12 Alpine container image
├── README.md                    # Documentation and execution verification
├── app/
│   ├── __init__.py
│   └── calculator.py            # Python calculator application
├── build.sh                     # Build and packaging script
├── requirements.txt             # Project dependencies (pytest)
└── tests/
    └── test_calculator.py       # Unit test suite
```
