#!/bin/bash

# Simple script to generate traffic against the php-apache service.
# Run this, then watch the HPA scale up in another terminal.

set -e

# Clear previous run if it exists
kubectl delete pod load-generator --ignore-not-found=true

echo "Starting load generator pod..."
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"

echo "Load generator running."
echo "Watch HPA with: kubectl get hpa php-apache-hpa -w"
echo "Stop it with:  kubectl delete pod load-generator"
