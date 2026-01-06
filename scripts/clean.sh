#!/usr/bin/env bash

usage() {
  echo "Description:"
  echo "  Clean up Docker containers and optionally volumes for specified services."
  echo "  Note: You will be prompted for confirmation before any volumes are removed."
  echo
  echo "Usage:"
  echo "  $0 clean <service>        Clean a single service"
  echo "  $0 clean all              Clean all services"
  echo
  echo "Examples:"
  echo "  $0 clean gitea            Clean the gitea service"
  echo "  $0 clean all              Clean all services"
}

cd $(dirname "${BASH_SOURCE[0]}") && cd ..

AVAILABLE_SERVICES=$(docker compose config --services)
REQUESTED_SERVICE="$1"

if [ "$REQUESTED_SERVICE" = "all" ]; then
  read -r -p "Would you like to clean up the volumes associated with all services? This action cannot be undone. (y/N): " CONFIRM_ALL_VOLUMES
  docker compose down

  if [[ "$CONFIRM_ALL_VOLUMES" = "y" || "$CONFIRM_ALL_VOLUMES" = "Y" ]]; then
    echo "Removing all volumes..."
    docker compose rm -fv
  fi
  exit 0
fi

# Service Validation
if ! echo "$AVAILABLE_SERVICES" | grep -q "^$REQUESTED_SERVICE$"; then
  echo "Error: Service '$1' not found."
  echo
  usage
  exit 1
fi

read -r -p "Would you like to clean up the volumes associated with the '$REQUESTED_SERVICE' service? This action cannot be undone. (y/N): " CONFIRM_VOLUMES
docker compose down "$REQUESTED_SERVICE"

if [[ "$CONFIRM_VOLUMES" = "y" || "$CONFIRM_VOLUMES" = "Y" ]]; then
  echo "Removing volumes for service '$REQUESTED_SERVICE'..."
  docker compose rm -fv "$REQUESTED_SERVICE"
fi
