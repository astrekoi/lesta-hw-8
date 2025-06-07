#!/bin/bash
set -e

echo "🔍 Проверка статуса minikube..."
if ! minikube status &>/dev/null; then
    echo "❌ Minikube не запущен. Запускаем..."
    minikube delete 2>/dev/null || true
    minikube start --driver=docker --memory=4096 --cpus=2

    echo "⏳ Ожидание готовности API сервера..."
    for i in {1..30}; do
        if kubectl cluster-info &>/dev/null; then
            echo "✅ API сервер готов"
            break
        fi
        echo "Попытка $i/30..."
        sleep 10
    done
fi

echo "🔧 Проверка аддонов..."
if ! minikube addons list | grep "storage-provisioner" | grep -q "enabled"; then
    minikube addons enable storage-provisioner
fi

if ! minikube addons list | grep "ingress" | grep -q "enabled"; then
    minikube addons enable ingress
fi

echo "🐳 Настройка Docker окружения..."
eval $(minikube docker-env)

echo "🏗️ Сборка Docker образа..."
docker build -t lesta-start:7.1 .

echo "🚀 Развертывание приложения..."
kubectl apply -f k8s/
kubectl apply -f k8s/logging/

echo "⏳ Ожидание готовности PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=180s

echo "⏳ Ожидание готовности приложения..."
kubectl wait --for=condition=ready pod -l app=lesta-app --timeout=180s

echo "🌐 Информация о доступе к приложению:"
NODEPORT=$(kubectl get service lesta-service -o jsonpath='{.spec.ports[0].nodePort}')
MINIKUBE_IP=$(minikube ip)

echo ""
echo "✅ Развертывание через k8s завершено успешно!"
echo ""
echo "📋 Способы доступа:"
echo "1. NodePort:     http://$MINIKUBE_IP:$NODEPORT"
echo "2. Ingress:      http://lesta.local"
echo "3. Тест ping:    curl http://$MINIKUBE_IP:$NODEPORT/ping"
echo ""
echo "🔧 Настройка hosts (для Ingress):"
echo "echo '$MINIKUBE_IP lesta.local' | sudo tee -a /etc/hosts"
echo ""
echo "🔍 Мониторинг:"
echo "kubectl get pods,svc,ingress"
echo "kubectl logs -f deployment/lesta-app"