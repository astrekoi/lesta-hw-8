#!/bin/bash

echo "🗑️ Удаление ресурсов Kubernetes..."
kubectl delete -f k8s/ --ignore-not-found=true

echo "🗑️ Удаление ресурсов логирования..."
kubectl delete -f k8s/logging/ --ignore-not-found=true

echo "🐳 Очистка Docker образов..."
eval $(minikube docker-env 2>/dev/null) || true
docker rmi lesta-start:7.1 2>/dev/null || echo "Образ lesta-start:7.1 не найден"

echo "✅ Очистка завершена!"
