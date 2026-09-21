#!/bin/bash

# Generates traffic against the web-service in production-webapp namespace.
# Use this to trigger the Horizontal Pod Autoscaler.

set -e

NAMESPACE="production-webapp"

# Remove existing load-generator if running
kubectl delete pod load-generator -n "$NAMESPACE" --ignore-not-found=true

echo "Starting load generator pod in namespace $NAMESPACE..."
kubectl run load-generator -n "$NAMESPACE" \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://web-service; done"

echo "Load generator running."
echo "Watch autoscaler with: kubectl get hpa web-app-hpa -n $NAMESPACE -w"
echo "Stop it with:          kubectl delete pod load-generator -n $NAMESPACE"
