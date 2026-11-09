SHELL := /bin/bash
COMPOSE := docker compose

.PHONY: up down restart ps logs load-on load-off reset

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) down
	$(COMPOSE) up -d --build

ps:
	$(COMPOSE) ps

# Usage: make logs            (all services)
#        make logs s=nginx    (one service)
logs:
	$(COMPOSE) logs -f --tail=100 $(s)

# The switch is stored in .env, so it survives make up and make restart.
load-on:
	sed -i 's/^ENABLED=.*/ENABLED=true/' .env
	$(COMPOSE) up -d load-generator

load-off:
	sed -i 's/^ENABLED=.*/ENABLED=false/' .env
	$(COMPOSE) up -d load-generator

reset:
	@read -r -p "This deletes all FinSim data (volumes). Continue? [y/N] " answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		$(COMPOSE) down -v && $(COMPOSE) up -d --build; \
	else \
		echo "Aborted"; \
	fi
