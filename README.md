# Cloud Computing Project: Flask + Celery + RabbitMQ + PostgreSQL + Flower on Kubernetes

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