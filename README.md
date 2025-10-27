# Cloud Computing Project: Flask + Celery + RabbitMQ + PostgreSQL + Flower on Kubernetes

> **Quick Start**: Want to run the Fibonacci demo right now? Scroll down to [🚀 Quick Start Guide](#quick-start-guide)!

## Project Overview

This project demonstrates a production-ready microservices architecture on Kubernetes with asynchronous task processing. The workflow models a realistic data-processing pipeline composed of five interacting services:

- **T1 Ingest**: RabbitMQ (Message Broker)
- **T2 Process**: Celery Workers (Asynchronous Task Processing)
- **T3 Store**: PostgreSQL (Persistent Storage)
- **T4 Visualize**: Flower Dashboard (Monitoring)
- **T5 Interface**: Flask API (Web Entrypoint)

### Team Members
- Chacko Happy
- Akeem Mohammed
- Kunal Koshti
- Ajwad Masood

**Instructor**: Dr. Il-Yeng Kim  
**Course**: CS 6343 – Cloud Computing

---

## 🚀 Quick Start Guide - Running the Fibonacci Demo

### Prerequisites (5 minutes setup)

1. **Docker Desktop** installed and running
2. **Enable Kubernetes** in Docker Desktop:
   - Open Docker Desktop → Settings (gear icon) → Kubernetes → Enable
   - Click "Apply & Restart"
   - Wait 2-3 minutes for setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/ak55m/cloud-computing-project-Fall-2025.git
cd cloud-computing-project-Fall-2025
```

### Step 2: Install Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

Wait for it to be ready:
```bash
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
```

### Step 3: Deploy the Application

```bash
./deploy.sh
```

This will:
- Create the namespace
- Deploy all services (Flask, Celery, RabbitMQ, PostgreSQL, Flower)
- Set up persistent storage
- Configure autoscaling
- Wait for all pods to be ready

### Step 4: Access the Fibonacci Calculator

**Port forward the ingress:**
```bash
INGRESS_SVC=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n ingress-nginx svc/$INGRESS_SVC 8080:80
```

**Open in your browser:**
- **Flask API**: http://localhost:8080/api
- **Flower Dashboard**: http://localhost:8080/flower

### Step 5: Test the Fibonacci Calculator

1. Go to http://localhost:8080/api
2. Enter a number in the text box (try **5** to start)
3. Click "Submit"
4. Watch the calculation happen!

**Try different numbers:**
- **n=5** → Instant result ⚡
- **n=20** → Takes ~2 seconds
- **n=30** → Takes ~20 seconds
- **n=35** → Takes several minutes (demonstrates autoscaling)

**Tip**: Open the Flower dashboard in another tab to watch workers process tasks in real-time!

---

## 📊 What You'll See

### When you submit a Fibonacci number:

1. **Flask API** receives your request instantly
2. Task is queued in **RabbitMQ**
3. Available **Celery Worker** picks up the task
4. Worker calculates Fibonacci (intentionally inefficient algorithm)
5. Result is stored in **PostgreSQL**
6. You see the result in the Flask UI

### Monitoring in Flower:

Visit http://localhost:8080/flower to see:
- Active workers and their status
- Task queue depth
- Completed tasks
- Failed tasks
- Worker statistics

---

## 🌸 Flower Dashboard - Complete Monitoring Guide

### What is Flower Dashboard?

Flower is a **real-time monitoring dashboard** for Celery workers. It provides complete visibility into your distributed task processing system.

### Dashboard Features

#### 1. **Overview Page** (http://localhost:8080/flower)
```
┌────────────────────────────────────────────────┐
│  Flower Dashboard - Celery Monitoring            │
├────────────────────────────────────────────────┤
│                                                 │
│  📊 Summary Statistics                          │
│  ├─ Active Workers: 3                          │
│  ├─ Tasks (total): 47                          │
│  ├─ Success: 45                                │
│  ├─ Pending: 2                                 │
│  └─ Failed: 0                                  │
│                                                 │
│  ⚙️  Worker Status                              │
│  ├─ celery-worker-xxx: Online (500m CPU)       │
│  ├─ celery-worker-yyy: Online (750m CPU)      │
│  └─ celery-worker-zzz: Online (300m CPU)       │
│                                                 │
└────────────────────────────────────────────────┘
```

#### 2. **Workers Tab**
- **Real-time worker status**: See which workers are active
- **Worker details**: 
  - CPU and memory usage
  - Task completion rate
  - Worker pool size
  - Start time and uptime
- **Worker controls**: Shut down or restart workers

#### 3. **Tasks Tab**
View all tasks in the system:
- **Task ID**: Unique identifier for each task
- **Name**: `fib_job`
- **Arguments**: The Fibonacci number being calculated
- **State**: SUCCESS, PENDING, STARTED, FAILURE
- **Time**: When task started/completed
- **Duration**: How long task took to execute
- **Result**: The calculated Fibonacci number

Example task list:
```
ID          Task      State    Started    Duration  Result
──────────  ────────  ───────  ─────────  ────────  ──────────
abc-123     fib_job   SUCCESS  14:30:15    0.5s      5
def-456     fib_job   SUCCESS  14:30:42    2.3s      6765
ghi-789     fib_job   SUCCESS  14:31:10    18.7s     832040
jkl-012     fib_job   PENDING  14:32:00    -         -
```

#### 4. **Broker Tab**
- **RabbitMQ Connection**: See if RabbitMQ is connected
- **Broker stats**: Messages queued, delivered, acked
- **Exchange information**

#### 5. **Monitor Tab**
Graphs and metrics:
- **Task rate**: Tasks per second
- **Worker load**: CPU usage over time
- **Task duration**: Average execution time
- **Queue depth**: Number of pending tasks

### How to Read the Dashboard

**When you're testing:**

1. **Submit a task** (n=30) from Flask API
2. **Watch in Flower:**
   - Task appears in "Tasks" tab with state **PENDING**
   - Soon changes to **STARTED** (worker picked it up)
   - Worker CPU usage spikes (see in Workers tab)
   - Task completes, state becomes **SUCCESS**
   - Result shows the Fibonacci number

3. **Try multiple tasks:**
   - Submit n=25, n=26, n=27, n=28
   - Watch all tasks queue up
   - See multiple workers pick them up in parallel
   - Notice different completion times based on number

### Real-Time Monitoring Example

```
Timeline of processing n=30:

14:32:00 [PENDING]  Task queued in RabbitMQ
14:32:00 [STARTED] Worker celery-worker-54b8 picked up task
14:32:02 [WORKING] Worker calculates fib(30)
                    ├─ Calculates fib(29) + fib(28)
                    ├─ Calculates fib(28) + fib(27)
                    ├─ ... (recursive calls)
14:32:18 [SUCCESS] Task completed in 18.2s
                    Result: 832040
```

### Dashboard Colors & Status

- **🟢 Green**: Worker online, task succeeded
- **🟡 Yellow**: Task pending in queue
- **🔵 Blue**: Task started, currently processing
- **🔴 Red**: Task failed, worker offline
- **⚪ White**: No activity

### Useful Dashboard Metrics

**For the Fibonacci Demo:**

1. **Queue Depth**: How many tasks are waiting
   - Empty = all workers busy or idle
   - High = heavy load, may need more workers

2. **Worker Load**: CPU usage per worker
   - Low (< 50%) = CPU not fully utilized
   - High (> 80%) = workers are working hard
   - HPA will scale up if consistently > 70%

3. **Task Duration**: How long tasks take
   - n=5: ~0.1s
   - n=20: ~2s
   - n=30: ~20s
   - n=35: Minutes (tests autoscaling)

### Tips for Using Flower

1. **Keep it open** while testing to see real-time processing
2. **Try large numbers** to see workers scale up automatically
3. **Check the Monitor tab** for performance graphs
4. **Use the Tasks search** to find specific tasks
5. **Watch worker load** to understand resource usage

---

## 🧹 Cleanup

When you're done testing:

```bash
kubectl delete namespace flask-celery
```

---

## Architecture

The application calculates Fibonacci numbers using an asynchronous microservices architecture:

1. **Flask API** receives HTTP requests and submits tasks to RabbitMQ
2. **RabbitMQ** queues tasks and distributes them to Celery workers
3. **Celery Workers** process tasks asynchronously
4. **PostgreSQL** stores task results persistently
5. **Flower Dashboard** provides monitoring and visibility

### Services Architecture

```
External User
     |
     | HTTP requests (via Ingress)
     v
┌────────────────────────────────────────────────────────┐
│ Kubernetes Cluster (Namespace: flask-celery)          │
│                                                        │
│  Ingress (/api → Flask, /flower → Flower)            │
│         |                     |                       │
│    Flask API (2 replicas)   Flower (Monitoring)       │
│         |                                             │
│    RabbitMQ StatefulSet (Message Broker)             │
│         |                                             │
│    Celery Workers (3-10 replicas, HPA enabled)      │
│         |                                             │
│    PostgreSQL StatefulSet (Database)                 │
└────────────────────────────────────────────────────────┘
```

---

## Prerequisites

- Docker Desktop with Kubernetes enabled
- `kubectl` command-line tool
- Access to pull images from Docker Hub

### Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Enable Kubernetes
4. Click "Apply & Restart"

### Install kubectl

```bash
# On macOS
brew install kubectl

# On Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo mv kubectl /usr/local/bin/
```

### Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for the ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

---

## Deployment Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/asoucase/flask-celery-kubernetes-example.git
cd flask-celery-kubernetes-example
```

### 2. Deploy to Kubernetes

Apply all manifests in the correct order:

```bash
kubectl apply -f manifests/
```

This will create:
- Namespace: `flask-celery`
- Secrets for app, database, and RabbitMQ
- ConfigMap for application configuration
- StatefulSets for RabbitMQ and PostgreSQL with persistent storage
- Deployments for Flask, Celery Workers, and Flower
- Services (ClusterIP) for all components
- Ingress controller routes
- Horizontal Pod Autoscaler for Celery workers

### 3. Verify Deployment

Check all pods are running:

```bash
kubectl get pods -n flask-celery
```

Expected output:
```
NAME                            READY   STATUS    RESTARTS   AGE
celery-worker-xxxxxxxxxxxx      1/1     Running   0          2m
celery-worker-xxxxxxxxxxxx      1/1     Running   0          2m
celery-worker-xxxxxxxxxxxx      1/1     Running   0          2m
flask-app-xxxxxxxxxxxx          1/1     Running   0          2m
flask-app-xxxxxxxxxxxx          1/1     Running   0          2m
flower-xxxxxxxxxxxx             1/1     Running   0          2m
postgres-0                      1/1     Running   0          2m
rabbitmq-0                      1/1     Running   0          2m
```

Check services:

```bash
kubectl get svc -n flask-celery
```

Check ingress:

```bash
kubectl get ingress -n flask-celery
```

### 4. Access the Application

#### Option A: Using localhost

Add to `/etc/hosts`:
```
127.0.0.1 flask-celery.local
```

Access the application:
- Flask API: http://flask-celery.local/api
- Flower Dashboard: http://localhost:32701/flower

#### Option B: Using Port Forwarding

Forward the ingress controller to localhost:

```bash
# Get the ingress controller service name
INGRESS_SVC=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')

# Port forward
kubectl port-forward -n ingress-nginx svc/$INGRESS_SVC 8080:80
```

Access the application:
- Flask API: http://localhost:8080/api
- Flower Dashboard: http://localhost:8080/flower

---

## Testing the Application

1. **Submit a task**:
   - Visit http://localhost:8080/api (or your ingress URL)
   - Enter a Fibonacci number (e.g., 5)
   - Click "Submit"
   - The task will be queued in RabbitMQ

2. **Monitor tasks**:
   - Visit http://localhost:8080/flower
   - View active workers and task status
   - Check completed tasks

3. **View results**:
   - Return to the Flask API
   - See the list of completed tasks with results

4. **Test autoscaling**:
   ```bash
   # Generate load to trigger HPA
   kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh
   
   # Inside the pod
   while true; do wget -q -O- http://flask-celery-ingress.flask-celery.svc.cluster.local/api; done
   
   # Watch HPA scaling
   kubectl get hpa -n flask-celery --watch
   ```

---

## Resource Management

### Resource Limits & QoS Classes

| Component | CPU/Memory Requests | CPU/Memory Limits | QoS Class |
|-----------|---------------------|-------------------|-----------|
| RabbitMQ | 250m/512Mi | 500m/1Gi | Burstable |
| Celery Worker | 500m/512Mi | 1 CPU/1Gi | Burstable |
| Flask API | 300m/256Mi | 500m/512Mi | Burstable |
| PostgreSQL | 1 CPU/2Gi | 2 CPU/4Gi | Guaranteed |
| Flower | 100m/128Mi | 300m/256Mi | Burstable |

### Persistent Storage

- **RabbitMQ**: 10Gi PVC for message queues
- **PostgreSQL**: 20Gi PVC for database data

### Autoscaling

Celery Workers use Horizontal Pod Autoscaler (HPA):
- **Min replicas**: 3
- **Max replicas**: 10
- **Scale trigger**: CPU > 70%
- **Scale behavior**: 
  - Scale up: 100% or +2 pods every 30s
  - Scale down: 50% every 60s (5 min stabilization)

---

## Monitoring & Debugging

### View logs

```bash
# Flask logs
kubectl logs -f deployment/flask-app -n flask-celery

# Celery worker logs
kubectl logs -f deployment/celery-worker -n flask-celery

# RabbitMQ logs
kubectl logs -f statefulset/rabbitmq -n flask-celery

# PostgreSQL logs
kubectl logs -f statefulset/postgres -n flask-celery
```

### Check pod status

```bash
kubectl describe pod <pod-name> -n flask-celery
```

### Monitor resource usage

```bash
# Top pods by CPU/Memory
kubectl top pods -n flask-celery

# Check HPA status
kubectl get hpa -n flask-celery
```

### Access Flower Dashboard

```bash
# Port forward Flower service
kubectl port-forward -n flask-celery svc/flower 5555:5555

# Open http://localhost:5555
```

---

## Cleanup

To remove the entire deployment:

```bash
kubectl delete namespace flask-celery
```

This will remove all resources including:
- All pods, deployments, and statefulsets
- Services and ingress
- Persistent volume claims
- Secrets and configmaps
- Horizontal pod autoscalers

**Note**: The PVC data will be deleted. If you want to preserve data, delete everything except PVCs:

```bash
# Delete pods and deployments but keep PVCs
kubectl delete deployment,statefulset,service,ingress,hpa -n flask-celery --all
```

---

## Troubleshooting

### Pods not starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n flask-celery

# Check PVC status
kubectl get pvc -n flask-celery
```

### Cannot access the application

```bash
# Check ingress status
kubectl get ingress -n flask-celery

# Check services
kubectl get svc -n flask-celery

# Verify endpoint connectivity
kubectl exec -it <flask-pod> -n flask-celery -- curl http://postgres:5432
```

### Database connection issues

```bash
# Check if PostgreSQL is ready
kubectl exec -it postgres-0 -n flask-celery -- psql -U demo -d demo

# Test connection from Flask pod
kubectl exec -it <flask-pod> -n flask-celery -- env | grep POSTGRES
```

### HPA not scaling

```bash
# Check HPA configuration
kubectl describe hpa celery-worker-hpa -n flask-celery

# Check metrics
kubectl top pods -n flask-celery
```

---

## Project Features Implemented

✅ **Multi-tier microservices architecture**  
✅ **StatefulSets for persistent storage** (RabbitMQ, PostgreSQL)  
✅ **Resource requests and limits** (QoS classes)  
✅ **Horizontal Pod Autoscaler** (3-10 worker replicas)  
✅ **Pod anti-affinity** for worker distribution  
✅ **NGINX Ingress** for external access  
✅ **ClusterIP services** for internal communication  
✅ **Persistent Volume Claims** (10Gi RabbitMQ, 20Gi PostgreSQL)  
✅ **Monitoring with Flower** dashboard  
✅ **High availability** with multiple Flask and Worker replicas  

---

## References

- Original repository: https://github.com/asoucase/flask-celery-kubernetes-example
- Flask documentation: https://flask.palletsprojects.com/
- Celery documentation: https://docs.celeryproject.org/
- Kubernetes documentation: https://kubernetes.io/docs/
- NGINX Ingress: https://kubernetes.github.io/ingress-nginx/

---

## License

MIT License - See LICENSE file for details.