#!/bin/bash
set -e

echo "🚀 Начинаем автоматическую установку Minikube, kubectl и настройку кластера..."

check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

echo "📦 Проверяем наличие Docker..."
if ! check_command docker; then
    echo "❌ Docker не найден. Установите Docker и запустите скрипт заново."
    echo "Инструкция: https://docs.docker.com/engine/install/"
    exit 1
fi

if ! groups $USER | grep &> /dev/null '\bdocker\b'; then
    echo "👤 Добавляем пользователя в группу docker..."
    sudo usermod -aG docker $USER
    echo "⚠️  Требуется перезапуск сессии или выполните: newgrp docker"
fi

echo "⚙️  Устанавливаем kubectl..."
if ! check_command kubectl; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "✅ kubectl установлен успешно"
else
    echo "✅ kubectl уже установлен"
fi

echo "⚙️  Устанавливаем Minikube..."
if ! check_command minikube; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo "✅ Minikube установлен успешно"
else
    echo "✅ Minikube уже установлен"
fi

echo "⚙️  Устанавливаем Helm..."
if ! check_command helm; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
    echo "✅ Helm установлен успешно"
else
    echo "✅ Helm уже установлен"
fi

echo "🎯 Запускаем Minikube кластер..."
if minikube status | grep -q "host: Running"; then
    echo "✅ Minikube кластер уже запущен"
else
    minikube start --driver=docker --cpus=2 --memory=2g
    echo "✅ Minikube кластер запущен успешно"
fi

echo "🌐 Включаем Ingress Controller..."
minikube addons enable ingress
echo "✅ Ingress Controller включен"

echo "🔍 Проверяем статус компонентов..."
kubectl get nodes
kubectl get pods -n ingress-nginx

echo "🎉 Установка завершена успешно!"
