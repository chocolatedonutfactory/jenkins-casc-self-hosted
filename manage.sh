#!/bin/bash
ENV=$1
ACTION=$2

if [ -z "$ENV" ] || [ -z "$ACTION" ]; then
  echo "Usage: ./manage.sh [dev|prod] [up|down|logs|ps|...]"
  exit 1
fi

if [ "$ENV" == "prod" ]; then
  COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
elif [ "$ENV" == "dev" ]; then
  # Automatically uses docker-compose.override.yml
  COMPOSE_FILES="" 
else
  echo "Invalid environment: $ENV. Use 'dev' or 'prod'."
  exit 1
fi

echo "Running in $ENV environment..."
docker compose $COMPOSE_FILES $ACTION "${@:3}"
