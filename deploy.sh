#!/bin/bash

set -e

echo "=========================================="
echo "Cloud Computing Project Deployment"
echo "=========================================="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install it first."
    exit 1
fi

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster."
    echo "Please make sure:"
    echo "  1. Docker Desktop is running"
    echo "  2. Kubernetes is enabled in Docker Desktop"
    echo "  3. kubectl context is set correctly"
    exit 1
fi

echo "✓ kubectl is connected to cluster"
echo ""

# Deploy manifests
echo "Deploying Kubernetes manifests..."
kubectl apply -f manifests/

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all -n flask-celery --timeout=300s

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Current status:"
kubectl get pods -n flask-celery
echo ""
echo "Services:"
kubectl get svc -n flask-celery
echo ""
echo "Ingress:"
kubectl get ingress -n flask-celery
echo ""
echo "To access the application:"
echo "  1. Port forward the ingress:"
echo "     INGRESS_SVC=\$(kubectl get svc -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')"
echo "     kubectl port-forward -n ingress-nginx svc/\$INGRESS_SVC 8080:80"
echo ""
echo "  2. Access the application at:"
echo "     Flask API: http://localhost:8080/api"
echo "     Flower: http://localhost:8080/flower"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/flask-app -n flask-celery"
echo ""

