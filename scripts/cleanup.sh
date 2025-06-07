#!/bin/bash
# Дописать
kubectl delete -f k8s/
eval $(minikube docker-env)
docker rmi lesta-start:7.1 2>/dev/null || true
