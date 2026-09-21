# Task 2: Horizontal Pod Autoscaler (HPA)

Hands-on setup for autoscaling workloads based on CPU usage. Covers metrics-server integration, CPU target thresholds, and watching pods scale out and back in.

---

## 1. How HPA works

The Horizontal Pod Autoscaler adjusts replica counts in a Deployment based on observed resource utilization.

The metrics pipeline flows from cAdvisor inside Kubelet up to the Metrics Server, which the HPA controller polls every 15 seconds:

<img width="8192" height="397" alt="HPA Metrics Pipeline and Control Loop" src="https://github.com/user-attachments/assets/9aab4f0b-5323-4412-969e-01027bfddbdb" />

---

## 2. Scaling formula

The autoscaler uses this formula to determine the desired replica count:

$$\text{DesiredReplicas} = \left\lceil \text{CurrentReplicas} \times \left( \frac{\text{CurrentMetricValue}}{\text{DesiredMetricValue}} \right) \right\rceil$$

For example, with 2 pods running, a 50% target, and incoming traffic pushing average CPU to 175%:

$$\text{DesiredReplicas} = \lceil 2 \times (175 / 50) \rceil = \lceil 7.0 \rceil = 7 \text{ pods}$$

---

## 3. Why CPU requests are required

HPA needs `resources.requests.cpu` defined on the container. Without it, the autoscaler cannot calculate the percentage utilization, and `kubectl get hpa` will report `TARGETS: <unknown>/50%`.

In `01-deployment.yaml`, each pod requests 100m (0.1 core):

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi
```

---

## 4. Manifests

### 4.1 Deployment (01-deployment.yaml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
  labels:
    app: php-apache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
        - name: php-apache
          image: registry.k8s.io/hpa-example
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
```

### 4.2 Service (02-service.yaml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    app: php-apache
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
      name: http
  selector:
    app: php-apache
```

### 4.3 HPA (03-hpa.yaml)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
  labels:
    app: php-apache
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
        - type: Pods
          value: 4
          periodSeconds: 15
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
```

---

## 5. Lab steps and verification

### 5.1 Enable metrics and deploy
```bash
minikube addons enable metrics-server

kubectl apply -f 01-deployment.yaml
kubectl apply -f 02-service.yaml
kubectl apply -f 03-hpa.yaml

kubectl get hpa php-apache-hpa
```

Terminal Output:
```text
deployment.apps/php-apache created
service/php-apache created
horizontalpodautoscaler.autoscaling/php-apache-hpa created

NAME             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   0%/50%    2         10        2          35s
```

<img src="https://github.com/user-attachments/assets/b959ba1d-ec08-455f-9ef7-881fd3c29749" alt="Initial HPA deployment with 2 idle replicas" width="100%" />

### 5.2 Generate load
Start the load generator script:
```bash
chmod +x load_generator.sh
./load_generator.sh
```

Terminal Output:
```text
Starting load generator pod...
pod/load-generator created
Load generator running.
Watch HPA with: kubectl get hpa php-apache-hpa -w
Stop it with:  kubectl delete pod load-generator
```

<img src="https://github.com/user-attachments/assets/9fb2ad6e-f3f8-4334-8cab-6cd1ec0e7a4a" alt="Load generator launch and pod creation" width="100%" />

### 5.3 Watch pods scale out
```bash
kubectl get hpa php-apache-hpa -w
```

Observed scaling events:
```text
NAME             REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   0%/50%     2         10        2          1m
php-apache-hpa   Deployment/php-apache   130%/50%   2         10        2          2m
php-apache-hpa   Deployment/php-apache   185%/50%   2         10        4          2m30s
php-apache-hpa   Deployment/php-apache   140%/50%   2         10        7          3m
php-apache-hpa   Deployment/php-apache   68%/50%    2         10        10         3m45s
php-apache-hpa   Deployment/php-apache   48%/50%    2         10        10         4m30s
```

Check CPU usage across pods during load:
```bash
kubectl top pods -l app=php-apache
```

Output:
```text
NAME                          CPU(cores)   MEMORY(bytes)
php-apache-7869f59fbf-8j49z   74m          22Mi
php-apache-7869f59fbf-c94kl   82m          24Mi
php-apache-7869f59fbf-dkw02   68m          21Mi
php-apache-7869f59fbf-e39sm   79m          23Mi
php-apache-7869f59fbf-fk28s   85m          25Mi
php-apache-7869f59fbf-g83js   71m          22Mi
php-apache-7869f59fbf-h83kx   77m          24Mi
php-apache-7869f59fbf-m92ld   66m          20Mi
php-apache-7869f59fbf-p02ls   81m          23Mi
php-apache-7869f59fbf-w93kd   72m          22Mi
```

<img src="https://github.com/user-attachments/assets/23ccea4d-9b65-4145-82b9-3d4f52a962dd" alt="HPA scaling out to 10 pods under stress load" width="100%" />

### 5.4 Stop load and verify scale down
Delete the load pod and monitor the scale-down behavior:
```bash
kubectl delete pod load-generator
kubectl get hpa php-apache-hpa -w
```

Output:
```text
NAME             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   0%/50%    2         10        10         6m
php-apache-hpa   Deployment/php-apache   0%/50%    2         10        5          11m
php-apache-hpa   Deployment/php-apache   0%/50%    2         10        2          12m
```

The replica count stays at 10 for the 5-minute stabilization window (`stabilizationWindowSeconds: 300`) to avoid rapid flapping before dropping back to the minimum of 2.

<img src="https://github.com/user-attachments/assets/4ab3ab87-192d-40d4-b867-f56563d82ebf" alt="HPA cooling down and returning to minimum replicas" width="100%" />
