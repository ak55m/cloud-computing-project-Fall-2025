# Quick Start Guide for Team Members

## 🔧 Prerequisites

Before you begin, make sure you have:

1. **Docker Desktop installed** and running
2. **Kubernetes enabled** in Docker Desktop
3. **kubectl** installed on your machine
4. **Git** installed

### Setting Up Prerequisites

#### 1. Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Click the Settings icon (gear icon) in the top-right
3. Navigate to "Kubernetes" in the left sidebar
4. Check the box "Enable Kubernetes"
5. Click "Apply & Restart"
6. Wait for Docker to restart (may take a few minutes)

#### 2. Install kubectl

**On macOS:**
```bash
brew install kubectl
```

**On Linux:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo mv kubectl /usr/local/bin/
chmod +x /usr/local/bin/kubectl
```

**Verify installation:**
```bash
kubectl version --client
```

---

## 🚀 Deployment Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/ak55m/cloud-computing-project-Fall-2025.git
cd cloud-computing-project-Fall-2025
```

### Step 2: Install NGINX Ingress Controller

The Ingress controller is required for external access to the application:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

Wait for the controller to be ready (this may take 1-2 minutes):

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

### Step 3: Deploy the Application

**Option A - Using the deployment script (Recommended):**
```bash
./deploy.sh
```

**Option B - Manual deployment:**
```bash
kubectl apply -f manifests/
```

### Step 4: Verify Deployment

Check that all pods are running:

```bash
kubectl get pods -n flask-celery
```

You should see all pods in "Running" status:
- 2 flask-app pods
- 3-10 celery-worker pods
- 1 flower pod
- 1 postgres-0 pod
- 1 rabbitmq-0 pod

Wait a few minutes if pods are starting up.

### Step 5: Access the Application

#### Method 1: Port Forwarding (Easiest)

Get the ingress controller service name:
```bash
INGRESS_SVC=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')
```

Port forward to localhost:
```bash
kubectl port-forward -n ingress-nginx svc/$INGRESS_SVC 8080:80
```

**Now access:**
- **Flask API**: http://localhost:8080/api
- **Flower Dashboard**: http://localhost:8080/flower

#### Method 2: Using /etc/hosts (Alternative)

Add to `/etc/hosts`:
```
127.0.0.1 flask-celery.local
```

Find the ingress controller port:
```bash
kubectl get svc -n ingress-nginx
```

Look for the port number under `PORT(S)`, then access:
- **Flask API**: http://localhost:PORT/api
- **Flower Dashboard**: http://localhost:PORT/flower

---

## 🧪 Testing the Application

### 1. Submit a Task

1. Go to http://localhost:8080/api
2. Enter a Fibonacci number (e.g., 5)
3. Click "Submit"
4. You should see a success message

### 2. Monitor in Flower

1. Go to http://localhost:8080/flower
2. You'll see:
   - Active workers
   - Task queue status
   - Completed tasks

### 3. View Results

1. Return to the Flask API page
2. Scroll down to see the list of completed tasks
3. Your Fibonacci calculation should appear

---

## 📊 Monitoring & Debugging

### View Logs

```bash
# Flask logs
kubectl logs -f deployment/flask-app -n flask-celery

# Celery worker logs
kubectl logs -f deployment/celery-worker -n flask-celery

# All logs at once
kubectl logs -f -l app=flask-app -n flask-celery
```

### Check Resource Usage

```bash
# View pod resource usage
kubectl top pods -n flask-celery

# View HPA status
kubectl get hpa -n flask-celery
```

### View Application Status

```bash
# Get all resources
kubectl get all -n flask-celery

# Describe a specific pod
kubectl describe pod <pod-name> -n flask-celery
```

---

## 🧹 Cleanup

When you're done testing:

```bash
# Delete the entire namespace (removes everything)
kubectl delete namespace flask-celery
```

This will remove:
- All pods and deployments
- Services and ingress
- Persistent volume claims
- Secrets and configmaps
- HPA

---

## ❓ Troubleshooting

### Issue: Pods stuck in "Pending" or "ContainerCreating"

**Solution:**
```bash
# Check pod events for errors
kubectl describe pod <pod-name> -n flask-celery

# Ensure Docker Desktop has enough resources allocated
# Settings → Resources → increase CPU/Memory
```

### Issue: Cannot connect to application

**Solution:**
```bash
# Check if ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl get ingress -n flask-celery
kubectl describe ingress -n flask-celery
```

### Issue: Database connection errors

**Solution:**
```bash
# Check PostgreSQL pod
kubectl logs postgres-0 -n flask-celery

# Test connection from Flask pod
kubectl exec -it deployment/flask-app -n flask-celery -- env | grep POSTGRES
```

### Issue: Workers not scaling

**Solution:**
```bash
# Check HPA status
kubectl get hpa -n flask-celery
kubectl describe hpa celery-worker-hpa -n flask-celery

# Check if metrics are available
kubectl top pods -n flask-celery
```

---

## 📚 Useful Commands Reference

```bash
# Get all resources in namespace
kubectl get all -n flask-celery

# Get services
kubectl get svc -n flask-celery

# Get ingress
kubectl get ingress -n flask-celery

# Get HPA
kubectl get hpa -n flask-celery

# Get PVCs
kubectl get pvc -n flask-celery

# Restart a deployment
kubectl rollout restart deployment/flask-app -n flask-celery

# Scale workers manually
kubectl scale deployment celery-worker --replicas=5 -n flask-celery

# View all events
kubectl get events -n flask-celery --sort-by='.lastTimestamp'
```

---

## 🎓 Project Details

**Course:** CS 6343 – Cloud Computing  
**Instructor:** Dr. Il-Yeng Kim  
**Team Members:**
- Chacko Happy
- Akeem Mohammed
- Kunal Koshti
- Ajwad Masood

**Architecture:**
- Flask API (2 replicas)
- Celery Workers (3-10 replicas with HPA)
- RabbitMQ (Message Broker with 10Gi persistent storage)
- PostgreSQL (Database with 20Gi persistent storage)
- Flower (Monitoring Dashboard)

**Key Features:**
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Resource limits and QoS classes
- ✅ Persistent storage for stateful services
- ✅ Pod anti-affinity for high availability
- ✅ NGINX Ingress for external access

---

## 📞 Need Help?

If you encounter issues:

1. Check the main [README.md](./README.md) for detailed documentation
2. Review the troubleshooting section above
3. Check logs using the commands provided
4. Ensure Docker Desktop has enough resources allocated

Good luck! 🚀

