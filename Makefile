SHELL := /bin/bash

# Usage: make <target> [env=prod|staging]. The default is prod.
env ?= prod
ifeq ($(filter $(env),prod staging),)
$(error env must be prod or staging, got: $(env))
endif

ENV_FILE := .env.$(env)
COMPOSE := docker compose -p finsim-$(env) --env-file $(ENV_FILE)

# Codespaces sets these in devcontainer.json. The defaults are for WSL.
SIM_HOME ?= $(HOME)/.devops-sim
SIM_SSH_PUBKEY ?= $(HOME)/.ssh/id_ed25519.pub
export SIM_HOME SIM_SSH_PUBKEY

PROD_NETWORK := finsim-prod_default
INFRA_COMPOSE := docker compose -p finsim-infra -f infra/docker-compose.yml --env-file .env.prod

.PHONY: up down restart ps logs load-on load-off reset prune infra-up infra-down infra-ps

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) down
	$(COMPOSE) up -d --build

ps:
	$(COMPOSE) ps

# Usage: make logs                       (all prod services)
#        make logs s=nginx               (one prod service)
#        make logs env=staging s=nginx   (one staging service)
logs:
	$(COMPOSE) logs -f --tail=100 $(s)

# The switch is stored in the env file, so it survives make up and make restart.
load-on:
	sed -i 's/^ENABLED=.*/ENABLED=true/' $(ENV_FILE)
	$(COMPOSE) up -d load-generator

load-off:
	sed -i 's/^ENABLED=.*/ENABLED=false/' $(ENV_FILE)
	$(COMPOSE) up -d load-generator

reset:
	@read -r -p "This deletes all FinSim $(env) data (volumes). Continue? [y/N] " answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		$(COMPOSE) down -v && $(COMPOSE) up -d --build; \
	else \
		echo "Aborted"; \
	fi

# Frees disk space. Volumes are kept, so FinSim data survives.
prune:
	@docker system df
	@read -r -p "This deletes unused images and the build cache, but not volumes. Continue? [y/N] " answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		docker image prune -a -f && docker builder prune -a -f; \
	else \
		echo "Aborted"; \
	fi

# legacy-vm-01 joins the prod network, so prod has to exist first.
infra-up:
	@docker network inspect $(PROD_NETWORK) >/dev/null 2>&1 || { echo "Prod network not found. Run: make up" >&2; exit 2; }
	bash infra/prepare.sh
	$(INFRA_COMPOSE) up -d --build

infra-down:
	$(INFRA_COMPOSE) down

infra-ps:
	$(INFRA_COMPOSE) ps
