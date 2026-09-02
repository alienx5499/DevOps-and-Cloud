# Docker Multi-Stage Builds and Application Deployment

Implementation and documentation for Docker multi-stage builds, container size optimization, and multi-service deployment based on the devops-hero coursework.

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Multi-Stage Build Architecture

Multi-stage builds separate the build environment from the minimal runtime environment. Build tools, intermediate caches, and source dev-dependencies remain in Stage 1, while only production assets are copied into Stage 2.

<img src="https://github.com/user-attachments/assets/f0bd85e1-1dfe-4f5c-99bd-977aee85b2dd" alt="Multi-Stage Build Architecture" width="100%" />

---

## 1. Task 1: Multi-Stage Dockerfile Execution

### 1.1 Dockerfile Implementation
```dockerfile
# Stage 1: Build & Dependencies
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Production Minimal Runtime
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev
COPY --from=builder /app/server.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

---

### 1.2 Build and Run Commands
```bash
cd "Docker Images/multi-stage-app"

# Build multi-stage image
docker build -t multistage-app .

# Run container mapped to host port 8080
docker run -d -p 8080:3000 --name multistage-container multistage-app
```

---

### 1.3 Verification & Application Output
```bash
curl http://localhost:8080
```

**Output:**
```html
<h1>Hello World from Docker multi-stage build</h1>
```

---

### 1.4 Container State (`docker ps`)
```bash
docker ps --filter "name=multistage-container"
```

**Output:**
```text
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                                         NAMES
113c7e86c57a   multistage-app   "docker-entrypoint.s…"   13 seconds ago   Up 12 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   multistage-container
```

<img src="https://github.com/user-attachments/assets/98f85432-d5f3-41b0-93d1-46ffa821cbee" alt="Multi-stage container execution and verification" width="100%" />


---

## 2. Task 2: Multi-Stage Optimization Benefits

| Metric / Aspect | Single-Stage Build | Multi-Stage Build | Benefit |
| :--- | :--- | :--- | :--- |
| **Image Size** | Large (~300MB - 1GB+) | Minimal (~120MB - 180MB) | 60-80% smaller footprint |
| **Attack Surface** | Includes npm, compilers, git | Only production runtime binaries | High security hardening |
| **Build Artifacts** | Retains devDependencies & logs | DevDependencies stripped via `--omit=dev` | Clean production environment |
| **Deployment Speed** | Slower CI/CD image pulls | Faster container startup and registry push | Optimized delivery pipeline |

---

## 3. Task 3: 3 Multi-Stack Docker Application Deployments

### Application 1: Node.js (Multi-Stage Build)
- **Image:** `multistage-app:latest`
- **Host Port:** `8080` (Container Port `3000`)
- **Command:** `docker run -d -p 8080:3000 --name multistage-container multistage-app`
- **Verification:** Returns `<h1>Hello World from Docker multi-stage build</h1>`

### Application 2: Python Microservice
- **Image:** `python-app:latest`
- **Host Port:** `8000` (Container Port `8000`)
- **Command:** `docker run -d -p 8000:8000 --name python-container python-app`
- **Verification:** Returns `<h1>Hello World from Python!</h1>`

### Application 3: Nginx Web Server
- **Image:** `nginx-app:latest`
- **Host Port:** `8083` (Container Port `80`)
- **Command:** `docker run -d -p 8083:80 --name nginx-container nginx-app`
- **Verification:** Returns `<h1>Hello World from Nginx!</h1>`

<img src="https://github.com/user-attachments/assets/53ae7405-3087-4804-991f-13b3839dbaca" alt="Multi-app container deployment verification" width="100%" />


---

## Summary Matrix

| Application | Technology | Dockerfile Type | Host Port | Target URL | Status |
| :--- | :--- | :--- | :---: | :--- | :---: |
| **Multi-Stage App** | Node.js + Express | Multi-Stage (`builder` + `production`) | `8080` | `http://localhost:8080` | Active |
| **Python Service** | Python 3.10 HTTP | Single-Stage Alpine | `8000` | `http://localhost:8000` | Active |
| **Nginx Web** | Nginx Alpine | Single-Stage Static Web | `8083` | `http://localhost:8083` | Active |
