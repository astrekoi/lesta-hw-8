# Домашнее задание: Go-приложение в Kubernetes + Система логирования

**Выполнил Зинченко Андрей в рамках домашней работы**

## Описание проекта

Проект включает:
1. **Развертывание Go-приложения** в Kubernetes с PostgreSQL
2. **Систему централизованного логирования** на основе Loki, Promtail и Grafana
3. **Nginx reverse proxy** для внешнего доступа к приложению и Grafana

## Структура проекта

```
├── Dockerfile                    # Multi-stage сборка Go приложения
├── Makefile                      # Автоматизация команд
├── README.md
├── api/                          # Go приложение со Swagger
│   ├── cmd/demo/main.go
│   ├── docs/                     # Swagger документация
│   ├── go.mod, go.sum
│   └── internal/                 # Бизнес-логика
│       ├── api/                  # REST API handlers
│       ├── config/               # Конфигурация
│       ├── db/                   # Работа с БД
│       └── logger/               # Логирование
├── images/
├── k8s/                          # Kubernetes манифесты
│   ├── configmap.yaml            # Конфигурация приложения
│   ├── deployment.yaml           # Развертывание приложения и БД
│   ├── service.yaml              # Сервисы
│   ├── ingress.yaml              # Ingress Controller
│   └── logging/                  # Система логирования
│       ├── grafana.yaml          # Grafana для визуализации
│       ├── loki-config.yaml      # Loki для хранения логов
│       └── promtail-config.yaml  # Promtail для сбора логов
└── scripts/                      # Автоматизация
    ├── cleanup.sh                # Очистка ресурсов
    ├── deploy.sh                 # Развертывание
    ├── nginx-setup.sh            # Настройка nginx
    └── setup.sh                  # Установка окружения
```

## 🚀 Быстрый запуск

### 1. Установка окружения
```bash
make setup
```
Автоматически устанавливает Docker, Minikube, kubectl и запускает кластер.

### 2. Развертывание приложения
```bash
make deploy
```
Развертывает Go-приложение с PostgreSQL и систему логирования.

### 3. Настройка внешнего доступа
```bash
make nginx
```
Настраивает nginx для доступа к приложению и Grafana извне.

## 🌐 Доступ к сервисам

После успешного развертывания доступны:

- **Go API:** `http://ВНЕШНИЙ_IP/ping`
- **Grafana:** `http://ВНЕШНИЙ_IP/grafana/` (admin/admin)
- **Swagger UI:** `http://ВНЕШНИЙ_IP/swagger/index.html`

## 📊 Система логирования

### Компоненты
- **Loki:** Хранение и индексация логов
- **Promtail:** Сбор логов из контейнеров Kubernetes
- **Grafana:** Визуализация и анализ логов

### Работа с логами в Grafana

#### **Важно: сначала необходимо добавить Loki как источник данных в Grafana**

Перед тем как переходить к просмотру логов, убедитесь, что в Grafana добавлен datasource Loki:

1. Перейдите в Grafana по адресу: `http:///grafana/`
2. Войдите с учетными данными (по умолчанию admin/admin)
3. В меню слева выберите **Configuration** (шестеренка) → **Data Sources**
4. Нажмите **Add data source** и выберите **Loki**
5. В поле **URL** введите: `http://loki:3100`
6. Нажмите **Save & Test**, чтобы проверить подключение

После успешного добавления источника данных можно переходить к работе с логами.

#### **Просмотр логов:**

1. **Переход к логам:**
   - Grafana → **Explore** → Выбрать источник **Loki**

2. **Основные LogQL запросы:**
   ```logql
   # Все логи приложения
   {app="lesta-app"}
   
   # Логи за последние 5 минут
   {app="lesta-app"}[5m]
   
   # HTTP запросы
   {app="lesta-app"} |= "Incoming request"
   
   # Ошибки приложения
   {app="lesta-app"} |= "error"
   
   # SQL запросы
   {app="lesta-app"} |= "SQL query executed"
   ```

3. **Создание дашборда:**
   - Dashboards → New → Dashboard → Add Panel
   - Выберите Loki как источник данных
   - Настройте запросы и визуализацию

## ⚙️ Конфигурация

### ConfigMap (k8s/configmap.yaml)
Централизованное управление настройками:
```yaml
data:
  API_PORT: "8080"
  DB_URL: "postgres://USER_DB:PWD_DB@postgres:5432/DB"
  POSTGRES_DB: "DB"
  POSTGRES_USER: "USER_DB"
  POSTGRES_PASSWORD: "PWD_DB"
```

### Nginx Reverse Proxy
Обеспечивает доступ через один внешний IP:
```nginx
# Grafana доступна по /grafana/
location /grafana/ {
    proxy_pass http://MINIKUBE_IP:30300/;
}

# Go API доступен по корневому пути
location / {
    proxy_pass http://MINIKUBE_IP:30080;
}
```

## 🛠️ Makefile команды

```bash
make setup         # Установка окружения
make deploy        # Развертывание приложения
make nginx         # Настройка nginx proxy
make cleanup       # Очистка ресурсов
make help          # Справка по командам
```

## 🔍 Диагностика и мониторинг

### Тестирование работы
```bash
# Проверка API
curl http://ВНЕШНИЙ_IP/ping

# Генерация активности для логов
for i in {1..10}; do
  curl http://ВНЕШНИЙ_IP/ping
  curl http://ВНЕШНИЙ_IP/api/v1/roll_dice -X POST -d '{"sides":6}'
  sleep 1
done
```

## 🏗️ Архитектура Kubernetes

### Deployments
- **lesta-app:** 2 реплики Go-приложения (порт 8080)
- **postgres:** 1 реплика PostgreSQL 16
- **grafana:** 1 реплика Grafana (порт 3000)
- **loki:** 1 реплика Loki (порт 3100)

### Services
- **lesta-service:** NodePort 30080 → приложение
- **grafana:** NodePort 30300 → Grafana
- **postgres:** ClusterIP → внутренний доступ к БД
- **loki:** ClusterIP → внутренний доступ к Loki

### DaemonSet
- **promtail:** Сбор логов на каждой ноде кластера

## 🔒 Безопасность

- Promtail работает с RBAC правами для доступа к Kubernetes API
- PostgreSQL изолирована внутри кластера
- Grafana доступна через nginx proxy с возможностью добавления аутентификации

## 📝 Особенности реализации

1. **Без hostNetwork:** Promtail использует кластерный DNS для подключения к Loki
2. **JSON парсинг:** Правильная обработка Docker JSON логов от Kubernetes
3. **ConfigMap:** Централизованное управление конфигурацией без Helm
4. **Nginx integration:** Единая точка входа для всех сервисов

## 🧹 Очистка ресурсов

```bash
make cleanup
```

Удаляет все Kubernetes ресурсы и Docker образы.

## 📈 Результат

Пример логов из запроса:

![logs](/images/image.png)