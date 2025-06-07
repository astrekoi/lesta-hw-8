Выполнил Зинченко Андрей в рамках домашней работы

# Домашнее задание: Развертывание Go-приложения в Kubernetes с Minikube

## Структура проекта
```
.
├── Dockerfile           # Multi-stage сборка Go-приложения
├── setup.sh             # Установка minikube, kubectl, helm
├── deploy.sh            # Развертывание через kubectl
├── deploy-helm.sh       # Развертывание через Helm Chart
├── cleanup.sh           # Очистка kubectl развертывания
├── cleanup-helm.sh      # Очистка Helm развертывания
├── test-helm.sh         # Тестирование Helm Chart
├── k8s/                 # Kubernetes манифесты
│   ├── deployment.yaml  # Deployments для app и postgres
│   ├── service.yaml     # Services с NodePort
│   └── ingress.yaml     # Ingress для внешнего доступа
├── helm/                # Helm Chart
│   └── lesta-chart/
│       ├── Chart.yaml   # Метаданные Chart
│       ├── values.yaml  # Конфигурационные значения
│       └── templates/   # Шаблоны Kubernetes ресурсов
└── api/                 # Исходный код Go-приложения
```

## Быстрый запуск

### Способ 1: Через kubectl (простой)
```
chmod +x *.sh
./setup.sh
./deploy.sh
```

### Способ 2: Через Helm Chart (продвинутый)
```
chmod +x *.sh
./setup.sh
./deploy-helm.sh
```

**После успешного развертывания:**
- NodePort доступ: `http://:30080`
- Ingress доступ:  `http://lesta.local` (требует настройку hosts)
- Проверка работы: `curl http://:30080/ping`

## Как работает Kubernetes развертывание

### 1. Kubernetes компоненты

#### Deployments
- **lesta-app:** 2 реплики Go-приложения с автоматическим рестартом
- **postgres:** 1 реплика PostgreSQL 16 с переменными окружения

#### Services
- **lesta-service:** NodePort (30080) для внешнего доступа к приложению
- **postgres:** ClusterIP для внутреннего доступа к БД

#### Ingress
- **lesta-ingress:** Маршрутизация HTTP трафика через NGINX Ingress Controller
- **Host:** lesta.local → lesta-service:80

### 2. Переменные окружения
```
env:
- name: API_PORT
  value: "8080"
- name: DB_URL
  value: "postgres://USER_DB:PWD_DB@postgres:5432/DB"
```

## Особенности реализации

### 1. Автоматизация установки окружения
```
# setup.sh автоматически устанавливает:
- Docker
- Minikube
- kubectl
- Helm
- Запускает кластер с Ingress Controller
```

### 2. Сетевая конфигурация
```
# NodePort для прямого доступа
service:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080

# Ingress для красивых URL
ingress:
  rules:
  - host: lesta.local
    http:
      paths:
      - path: /
        backend:
          service:
            name: lesta-service
```

### 3. Helm параметризация
```
# values.yaml позволяет легко изменять:
app:
  replicas: 2              # Количество реплик
  image: lesta-start:7.1   # Версия образа

postgres:
  database: "DB"           # Имя базы данных
  user: "USER_DB"          # Пользователь БД

service:
  app:
    nodePort: 30080        # Внешний порт
```

## Мониторинг и диагностика

### Проверка статуса
```
# Статус подов
kubectl get pods

# Статус сервисов
kubectl get svc

# Логи приложения
kubectl logs -f deployment/lesta-app

# Helm релизы
helm list
helm status lesta-app
```

### Доступ к приложению
- **Локальный доступ:** `minikube ip` + NodePort 30080
- **Внешний доступ:** Через SSH туннель или проброс портов
- **Мониторинг:** `kubectl logs -f deployment/lesta-app`

## Очистка ресурсов

### kubectl
```
./cleanup.sh
```

### Helm  
```
./cleanup-helm.sh
```

## Проверка работы

Успешное развертывание можно проверить:
- Статус подов: все в состоянии `Running`
- Доступность эндпоинта `/ping`
- Логи без ошибок подключения к БД
```

![проверка работы](./images/image.png)