#!/bin/bash

echo "🔍 Checking deployment status..."
echo ""

# Check if pods are running
PODS=$(kubectl get pods -n flask-celery 2>/dev/null)

if [ -z "$PODS" ]; then
    echo "❌ Application not deployed yet!"
    echo ""
    echo "Deploying now..."
    ./deploy.sh
else
    echo "📊 Current pod status:"
    kubectl get pods -n flask-celery
    echo ""
fi

echo "⏳ Waiting for all pods to be ready..."
sleep 10

kubectl wait --for=condition=ready pod --all -n flask-celery --timeout=300s 2>/dev/null

echo ""
echo "✅ Application is ready!"
echo ""
echo "📊 Final status:"
kubectl get pods -n flask-celery
echo ""

# Get the ingress controller service
INGRESS_SVC=$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$INGRESS_SVC" ]; then
    echo "⚠️  Ingress controller not found. Please wait a moment and run this script again."
    exit 1
fi

echo "=========================================="
echo "🚀 Fibonacci Demo - Ready to Use!"
echo "=========================================="
echo ""
echo "Step 1: Port forward the ingress to access the app:"
echo ""
echo "   kubectl port-forward -n ingress-nginx svc/$INGRESS_SVC 8080:80"
echo ""
echo "Step 2: In a NEW terminal, access the application:"
echo ""
echo "   Flask API:  http://localhost:8080/api"
echo "   Flower:     http://localhost:8080/flower"
echo ""
echo "Step 3: Test the Fibonacci calculator:"
echo ""
echo "   1. Type a number (try 5 for quick results)"
echo "   2. Click Submit"
echo "   3. Watch it calculate!"
echo ""
echo "Try different numbers:"
echo "   - n=5    → Instant (0.1s)"
echo "   - n=20   → Fast (2s)"
echo "   - n=30   → Medium (20s)"
echo "   - n=35   → Slow (minutes)"
echo ""
echo "💡 Tip: Open Flower dashboard in another tab to watch workers process tasks!"
echo ""

