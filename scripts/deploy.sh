#!/bin/bash
# deploy.sh <env> <git-ref>
# run this on the server after you merged. ask me if it breaks  -- oleg

ENV=$1
REF=$2

if [ -z "$ENV" ] || [ -z "$REF" ]; then
    echo "usage: deploy.sh <env> <git-ref>"
    exit 1
fi

SRC=$(cd "$(dirname "$0")/.." && git remote get-url origin)
DIR=${SIM_HOME:-$HOME/.devops-sim}/deploy/$ENV

if [ ! -d "$DIR" ]; then
    mkdir -p "$(dirname "$DIR")"
    git clone "$SRC" "$DIR"
fi

cd "$DIR" || exit 1

[ -f ".env.$ENV" ] || cp ".env.$ENV.example" ".env.$ENV"

git fetch origin
git checkout "origin/$REF" 2>/dev/null || git checkout "$REF"

docker compose -p "finsim-$ENV" --env-file ".env.$ENV" build
docker compose -p "finsim-$ENV" --env-file ".env.$ENV" up -d

echo "deployed $REF to $ENV"
