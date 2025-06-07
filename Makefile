.PHONY: help setup deploy deploy-helm cleanup cleanup-helm test-helm nginx ensure-scripts

help:
	@echo "Доступные команды:"
	@echo "  make setup         - Установить окружение (minikube, kubectl)"
	@echo "  make deploy        - Развернуть через kubectl (scripts/deploy.sh)"
	@echo "  make cleanup       - Очистить ресурсы kubectl (scripts/cleanup.sh)"
	@echo "  make nginx         - Установить и настроить nginx proxy (scripts/nginx-setup.sh)"
	@echo "  make ensure-scripts - Дать права на выполнение всем скриптам"

ensure-scripts:
	@echo "🔧 Выдача прав на выполнение скриптам..."
	chmod +x scripts/*.sh

setup: ensure-scripts
	bash scripts/setup.sh

deploy: ensure-scripts
	bash scripts/deploy.sh

cleanup: ensure-scripts
	bash scripts/cleanup.sh

nginx: ensure-scripts
	bash scripts/nginx-setup.sh
