#!/bin/bash
set -e

MINIKUBE_IP=$(minikube ip)
API_NODEPORT=30080
GRAFANA_NODEPORT=30300
LOKI_NODEPORT=31000

echo "🔧 Установка nginx..."
sudo apt update -y
sudo apt install -y nginx

echo "📝 Настройка reverse proxy..."
sudo tee /etc/nginx/sites-available/lesta > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Grafana
    location /grafana/ {
        proxy_pass http://$MINIKUBE_IP:$GRAFANA_NODEPORT/grafana/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Loki API
    location /loki/ {
        proxy_pass http://$MINIKUBE_IP:$LOKI_NODEPORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Основное приложение
    location / {
        proxy_pass http://$MINIKUBE_IP:$API_NODEPORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo "🔗 Активация конфигурации..."
sudo ln -sf /etc/nginx/sites-available/lesta /etc/nginx/sites-enabled/lesta
sudo rm -f /etc/nginx/sites-enabled/default

echo "🛠️ Проверка конфигурации nginx..."
sudo nginx -t

echo "🔄 Запуск/перезапуск nginx..."
if sudo systemctl is-active --quiet nginx; then
    echo "Nginx активен, перезагружаем конфигурацию..."
    sudo systemctl reload nginx
else
    echo "Nginx не активен, запускаем сервис..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

echo "🔓 Открытие порта 80 в firewall (ufw)..."
sudo ufw allow 80

echo "📊 Проверка статуса nginx..."
sudo systemctl status nginx --no-pager

echo "✅ Nginx настроен!"
echo "Приложение доступно:     http://<ВНЕШНИЙ_IP_СЕРВЕРА>/ping"
echo "Grafana доступна по:     http://<ВНЕШНИЙ_IP_СЕРВЕРА>/grafana/"
echo "Loki API доступен по:     http://<ВНЕШНИЙ_IP_СЕРВЕРА>/loki/"
