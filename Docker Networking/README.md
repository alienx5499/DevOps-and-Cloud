# Docker Networking and Volume Management

Practical implementation, container network segmentation, host network drivers, bind mounts, and overlay network architecture based on the devops-hero coursework.

---

## Network Architecture & Isolation Flow

<img src="https://github.com/user-attachments/assets/845eb2cb-316c-477f-8ba3-e56f9df99d37" alt="Docker Network Architecture and Isolation Flow" width="100%" />

---

## 1. Task 1: Docker Container Networking & Multi-Network Isolation

### 1.1 Create Custom Docker Networks
```bash
docker network create frontend-net
docker network create backend-net
docker network create db-net
```

---

### 1.2 Launch Containers and Connect Dual Interfaces
```bash
# Launch frontend in frontend-net
docker run -d --name frontend-container --network frontend-net alpine sleep 3600

# Launch backend in frontend-net and connect to db-net
docker run -d --name backend-container --network frontend-net alpine sleep 3600
docker network connect db-net backend-container

# Launch database in db-net
docker run -d --name db-container --network db-net alpine sleep 3600
```

---

### 1.3 Connectivity & Isolation Verification

#### Test A: Frontend -> Backend (Allowed)
```bash
docker exec frontend-container ping -c 2 backend-container
```
**Output:**
```text
PING backend-container (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.059 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.080 ms

--- backend-container ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.059/0.069/0.080 ms
```

#### Test B: Frontend -> Database (Blocked by Network Boundary)
```bash
docker exec frontend-container ping -c 2 db-container
```
**Output:**
```text
ping: bad address 'db-container'
```

#### Test C: Backend -> Database (Allowed via `db-net`)
```bash
docker exec backend-container ping -c 2 db-container
```
**Output:**
```text
PING db-container (172.20.0.3): 56 data bytes
64 bytes from 172.20.0.3: seq=0 ttl=64 time=0.078 ms
64 bytes from 172.20.0.3: seq=1 ttl=64 time=0.185 ms

--- db-container ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.078/0.131/0.185 ms
```

<img src="https://github.com/user-attachments/assets/46552db3-3d0e-4262-b786-690142220a68" alt="Task 1 Network Isolation Verification" width="100%" />


---

## 2. Task 2: Host Network Mode (`--network host`)

### 2.1 Concept & Mechanics
When running a container with `--network host`, Docker skips creating an isolated network namespace or virtual bridge (`veth` pair). The container shares the host machine's physical network stack, IP address, and port namespace directly.

### 2.2 Execution Command
```bash
# Pull Apache image
docker pull httpd:alpine

# Run container on host network
docker run -d --name apache-host-container --network host httpd:alpine
```

### 2.3 Verification
```bash
docker run --rm --network host alpine wget -qO- http://localhost:80
```

**Output:**
```html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>
```

### Key Considerations:
- Port publishing (`-p 80:80`) is ignored because the container binds directly to host port `80`.
- Offers higher network throughput by eliminating NAT (Network Address Translation) and bridge overhead.

<img src="https://github.com/user-attachments/assets/3eb07dbe-aed0-4fba-80a7-1c15814ebef3" alt="Task 2 Host Network execution" width="100%" />


---

## 3. Task 3: Bind Mounts and Real-Time Hot Reloading

### 3.1 Setup Local Directory and File
```bash
mkdir -p "Docker Networking/html-bind"
echo "<h1>Hello students</h1>" > "Docker Networking/html-bind/index.html"
```

---

### 3.2 Run Nginx with Read-Only Bind Mount
```bash
docker run -d -p 8085:80 \
  -v "$(pwd)/Docker Networking/html-bind":/usr/share/nginx/html:ro \
  --name bindmount-nginx nginx:alpine
```

---

### 3.3 Verify Initial Content
```bash
curl http://localhost:8085
```
**Output:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Bind Mount Demo</title>
</head>
<body>
  <h1>Hello students</h1>
</body>
</html>
```

---

### 3.4 Live Modification Without Container Restart
```bash
echo '<h1>Hello students - Live Hot Reloaded Content</h1>' > html-bind/index.html
curl http://localhost:8085
```
**Output:**
```html
<h1>Hello students - Live Hot Reloaded Content</h1>
```

### Observation:
Changes made on the host filesystem are instantly reflected inside the running container without requiring `docker restart` or rebuilding the image.

<img src="https://github.com/user-attachments/assets/b5b515d8-4abe-4d0a-a990-63432e543aa3" alt="Task 3 Bind Mount Live Reload" width="100%" />


---

## 4. Task 4: Docker Overlay Networks

### 4.1 What is an Overlay Network?
An **Overlay Network** creates a distributed virtual Layer 2 network across multiple Docker host nodes in a Docker Swarm or cluster. Containers attached to an overlay network can communicate securely as if they were on the exact same local bridge, regardless of which physical host runs them.

### 4.2 Overlay Architecture (VXLAN Encapsulation)

<img src="https://github.com/user-attachments/assets/4db4a4a1-7f92-44e1-9c4f-d1671dfb9d6e" alt="Docker Overlay Network Architecture" width="100%" />


---

### 4.3 Key Features & Use Cases

1. **Automatic Routing Mesh**: Incoming traffic on any cluster node is automatically routed to the active container replica.
2. **Built-in IPAM & Service Discovery**: Docker automatically assigns internal IPs and provides DNS resolution across cluster nodes.
3. **Encrypted Data Plane**: Supports IPSec AES encryption (`--opt encrypted`) for secure multi-cloud or hybrid infrastructure communication.
4. **Primary Use Cases**:
   - Production Docker Swarm service deployments.
   - Multi-host microservice architectures requiring isolated inter-service communication.
   - Zero-downtime rolling service upgrades across diverse compute instances.

---

## Docker Network Drivers Comparison

| Driver | Scope | Use Case | Port Mapping | Isolation Level |
| :--- | :--- | :--- | :---: | :--- |
| **Bridge** | Single Host | Default container communication | Required (`-p`) | High (Per network) |
| **Host** | Single Host | Maximum performance, low latency | None (Direct) | Lowest (Shared stack) |
| **Overlay** | Multi-Host (Swarm) | Distributed microservices & clusters | Routing mesh | High (Encapsulated) |
| **None** | Single Host | Complete air-gapped isolation | Disabled | Complete Isolation |
| **Macvlan** | Single Host / LAN | Assign real physical MAC & LAN IP | Direct | Routed via LAN switch |
