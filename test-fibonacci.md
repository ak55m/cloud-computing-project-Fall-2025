# Fibonacci Demo - What Happens When You Run It

## 🎯 What This Demo Does

This project demonstrates **asynchronous microservices** using a simple but intentionally inefficient Fibonacci calculator.

### The Workflow:

```
You (Browser)
    ↓
Flask API → Receives your request
    ↓
RabbitMQ Queue → Holds your task
    ↓  
Celery Worker → Processes task (calculates Fibonacci)
    ↓
PostgreSQL → Stores result
    ↓
You (Browser) → Sees the result
```

### Why It's "Inefficient"?

Look at the code in `flask_app/tasks.py` line 12-18:

```python
def fib(n):
    if n == 1:
        return 0
    elif n == 2:
        return 1
    else:
        return fib(n-1)+fib(n-2)  # ← This is slow by design!
```

This uses recursive Fibonacci calculation, which:
- Calculates the same numbers multiple times
- Grows exponentially with larger inputs
- Is intentionally inefficient to demonstrate:
  - Task queuing works properly
  - Multiple workers can process tasks
  - System handles long-running tasks
  - Autoscaling kicks in under load

## 📊 What You'll See When Testing

### 1. **Small Numbers (1-10)**
- ✅ Returns instantly
- ✅ Shows how fast the system can be
- ✅ Good for basic testing

### 2. **Medium Numbers (15-25)**
- ⏱️ Takes a few seconds
- 💪 Shows background processing
- 👀 You can see it in Flower dashboard

### 3. **Large Numbers (30+)**
- ⏱️ Takes minutes or hours
- 🔥 Demonstrates scaling under load
- 📈 Multiple workers can handle multiple requests
- 🎯 Shows production-like behavior

## 🎮 How to Test

### Step 1: Enable Kubernetes

1. Open **Docker Desktop**
2. Click the **Settings** icon (gear)
3. Go to **Kubernetes**
4. Check **"Enable Kubernetes"**
5. Click **"Apply & Restart"**
6. Wait 2-3 minutes for setup

### Step 2: Install Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

Wait 1-2 minutes:
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

### Step 3: Deploy the Application

```bash
./deploy.sh
```

Wait for all pods to be "Running":
```bash
kubectl get pods -n flask-celery
```

### Step 4: Access the Application

Port forward the ingress:
```bash
INGRESS_SVC=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n ingress-nginx svc/$INGRESS_SVC 8080:80
```

Now open:
- **Flask API**: http://localhost:8080/api
- **Flower Dashboard**: http://localhost:8080/flower

### Step 5: Test the Fibonacci Calculator

**Try these numbers in order:**

1. **Start Small (n=5)**
   - Type: `5`
   - Submit
   - Result: Instant, shows number `3`
   - Why: Small calculations are fast

2. **Go Medium (n=20)**
   - Type: `20`
   - Submit  
   - Result: Takes ~2 seconds
   - Watch in Flower: See task in queue → worker processing → completed

3. **Make it Work Hard (n=30)**
   - Type: `30`
   - Submit
   - Result: Takes ~20-30 seconds
   - Flower: Shows active worker
   - This is where autoscaling would kick in under load!

4. **Really Stress It (n=35+)**
   - Type: `35`
   - Result: Takes several minutes
   - ⚠️ **Warning**: This will take a while!
   - You can see multiple workers in Flower

## 📈 What Happens Behind the Scenes

### When you submit n=30:

1. **0.1s** - Flask receives your request
2. **0.2s** - Job stored in PostgreSQL
3. **0.3s** - Task sent to RabbitMQ queue
4. **0.4s** - Available worker picks up task
5. **1s** - Worker starts processing
6. **Duration** - Worker calculates fib(29) + fib(28) recursively
   - Each call spawns 2 more calls
   - This creates exponential growth
7. **20-30s** - Worker completes
8. **Result** - Stored in PostgreSQL
9. **Display** - Shows in your browser

### Watch it Live:

Open two browser tabs:
- **Tab 1**: Flower Dashboard - See workers processing
- **Tab 2**: Flask API - Submit tasks and view results

## 🔥 Advanced Testing

### Test Autoscaling

1. Submit multiple large numbers at once (n=25, n=26, n=27, n=28)
2. Watch Flower - you'll see all tasks queued
3. Multiple workers will pick them up
4. Check HPA status:
   ```bash
   kubectl get hpa -n flask-celery
   ```

### Generate Load Test

In a terminal:
```bash
# Submit 10 simultaneous requests
for i in {20..30}; do
  curl -X POST http://localhost:8080/api/add \
    -d "n=$i" \
    & 
done
wait

# Watch in Flower - all tasks process in parallel!
```

### Monitor Resources

```bash
# Watch pods scaling
watch kubectl get pods -n flask-celery

# Check resource usage
kubectl top pods -n flask-celery

# View HPA scaling
kubectl get hpa -n flask-celery --watch
```

## 🧹 Cleanup

When done testing:
```bash
kubectl delete namespace flask-celery
```

## 🎓 Why This Demonstrates Cloud Computing

✅ **Microservices** - Flask, Celery, RabbitMQ, PostgreSQL, Flower  
✅ **Asynchronous Processing** - Tasks don't block the API  
✅ **Horizontal Scaling** - Add workers as load increases  
✅ **Resource Management** - CPU/Memory limits enforced  
✅ **Persistent Storage** - Data survives pod restarts  
✅ **Monitoring** - Flower dashboard shows real-time status  
✅ **Load Balancing** - Multiple Flask replicas  
✅ **High Availability** - Pod anti-affinity spreads workers  

This is **production-grade architecture** running on your laptop! 🚀

