#!/bin/bash

echo "🔍 Checking Kubernetes cluster status..."
echo ""

# Function to check if Kubernetes is ready
check_k8s() {
    if kubectl get nodes &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Wait for Kubernetes to be ready (max 5 minutes)
echo "⏳ Waiting for Kubernetes cluster to be ready..."
COUNTER=0
while ! check_k8s; do
    COUNTER=$((COUNTER+1))
    if [ $COUNTER -gt 60 ]; then
        echo "❌ Timeout: Kubernetes cluster is taking too long to start"
        echo "Please check Rancher Desktop is running and Kubernetes is enabled"
        exit 1
    fi
    sleep 5
    echo "   Still waiting... ($COUNTER/60 checks)"
done

echo ""
echo "✅ Kubernetes is ready!"
kubectl get nodes

echo ""
echo "📦 Deploying the Fibonacci Demo application..."
echo ""

# Deploy manifests
kubectl apply -f manifests/

echo ""
echo "⏳ Waiting for all pods to start..."
kubectl wait --for=condition=ready pod --all -n flask-celery --timeout=300s

echo ""
echo "=========================================="
echo "🎉 Deployment Complete!"
echo "=========================================="
echo ""
kubectl get pods -n flask-celery
echo ""
echo "📊 Current status:"
kubectl get all -n flask-celery
echo ""
echo "Next steps:"
echo "1. Port forward the ingress:"
echo "   INGRESS_SVC=\$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')"
echo "   kubectl port-forward -n ingress-nginx svc/\$INGRESS_SVC 8080:80"
echo ""
echo "2. Access the application:"
echo "   Flask API: http://localhost:8080/api"
echo "   Flower: http://localhost:8080/flower"
echo ""

