# Docker Fundamentals: Multi-Language Hello World Web Applications

Practical implementation, Dockerfiles, container builds, and execution commands for multi-stack Hello World web applications containerized with Docker.

<img src="https://github.com/user-attachments/assets/fc476d5f-db8d-4aa8-baeb-360854bf1196" alt="Docker Hello World Architecture" width="100%" />

---

## Directory Structure

```text
Docker Fundamentals/
├── Apache-app/
│   ├── Dockerfile
│   └── index.html
├── React-app/
│   ├── Dockerfile
│   └── index.html
├── java-app/
│   ├── Dockerfile
│   └── HelloServer.java
├── nginx-app/
│   ├── Dockerfile
│   └── index.html
├── nodejs-app/
│   ├── Dockerfile
│   └── server.js
├── python-app/
│   ├── Dockerfile
│   └── app.py
└── README.md
```

---

## 1. Node.js Application (`nodejs-app`)

### Build & Run Commands:
```bash
cd "Docker Fundamentals/nodejs-app"
docker build -t nodejs-app .
docker run -d -p 3000:3000 --name nodejs-container nodejs-app
```

### Verification:
```bash
curl http://localhost:3000
```

**Output:**
```html
<h1>Hello World from Node.js!</h1>
```

<img src="https://github.com/user-attachments/assets/e6633e6c-ee47-4b1e-84ea-1ac7d3879c92" alt="nodejs-app build and run" width="100%" />


---

## 2. Python Application (`python-app`)

### Build & Run Commands:
```bash
cd "Docker Fundamentals/python-app"
docker build -t python-app .
docker run -d -p 8000:8000 --name python-container python-app
```

### Verification:
```bash
curl http://localhost:8000
```

**Output:**
```html
<h1>Hello World from Python!</h1>
```

<img src="https://github.com/user-attachments/assets/9fcfdc2b-ad4c-482d-bf39-ac9e2fc2c2bb" alt="python-app build and run" width="100%" />


---

## 3. Java Application (`java-app`)

### Build & Run Commands:
```bash
cd "Docker Fundamentals/java-app"
docker build -t java-app .
docker run -d -p 8080:8080 --name java-container java-app
```

### Verification:
```bash
curl http://localhost:8080
```

**Output:**
```html
<h1>Hello World from Java!</h1>
```

<img src="https://github.com/user-attachments/assets/7b026527-0d82-43f9-b066-2a3e6b591140" alt="java-app build and run" width="100%" />


---

## 4. Apache Web Server (`Apache-app`)

### Build & Run Commands:
```bash
cd "Docker Fundamentals/Apache-app"
docker build -t apache-app .
docker run -d -p 8081:80 --name apache-container apache-app
```

### Verification:
```bash
curl http://localhost:8081
```

**Output:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Apache App</title>
</head>
<body>
  <h1>Hello World from Apache HTTP Server!</h1>
</body>
</html>
```

<img src="https://github.com/user-attachments/assets/b6edcd90-d77c-4cc6-b8cb-bbdbfa566e7e" alt="apache-app build and run" width="100%" />

---

## 5. React Application (`React-app`)

### Build & Run Commands:
```bash
cd "Docker Fundamentals/React-app"
docker build -t react-app .
docker run -d -p 8082:80 --name react-container react-app
```

### Verification:
```bash
curl http://localhost:8082
```

**Output:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>React Hello World App</title>
  <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
</head>
<body>
  <div id="root"></div>
  <script type="text/babel">
    function App() {
      return (
        <div>
          <h1>Hello World from React!</h1>
          <p>Running inside a Docker container via Nginx.</p>
        </div>
      );
    }
    const root = ReactDOM.createRoot(document.getElementById('root'));
    root.render(<App />);
  </script>
</body>
</html>
```

<img src="https://github.com/user-attachments/assets/a1f58fc2-39e5-4b7f-a013-f68832088497" alt="react-app build and run" width="100%" />

---

## 6. Nginx Web Server (`nginx-app`)

### Build & Run Commands:
```bash
cd "Docker Fundamentals/nginx-app"
docker build -t nginx-app .
docker run -d -p 8083:80 --name nginx-container nginx-app
```

### Verification:
```bash
curl http://localhost:8083
```

**Output:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Nginx App</title>
</head>
<body>
  <h1>Hello World from Nginx!</h1>
</body>
</html>
```

<img src="https://github.com/user-attachments/assets/28b4323a-6687-4ae3-9f78-514cd29c8957" alt="nginx-app build and run" width="100%" />

---

## Applications Summary Matrix

| Application | Folder | Base Image | Container Port | Host Port | Verification URL |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **Node.js** | `./nodejs-app` | `node:18-alpine` | `3000` | `3000` | `http://localhost:3000` |
| **Python** | `./python-app` | `python:3.10-alpine` | `8000` | `8000` | `http://localhost:8000` |
| **Java** | `./java-app` | `amazoncorretto:17-alpine` | `8080` | `8080` | `http://localhost:8080` |
| **Apache** | `./Apache-app` | `httpd:alpine` | `80` | `8081` | `http://localhost:8081` |
| **React** | `./React-app` | `nginx:alpine` | `80` | `8082` | `http://localhost:8082` |
| **Nginx** | `./nginx-app` | `nginx:alpine` | `80` | `8083` | `http://localhost:8083` |
