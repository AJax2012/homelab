#!/usr/bin/env bash

usage() {
  echo "Description:"
  echo "  Start a single service or all services in the homelab environment."
  echo
  echo "Usage:"
  echo "  $0 start <service>        Start a single service"
  echo "  $0 start all              Start all services"
  echo
  echo "Examples:"
  echo "  $0 start gitea            Start the gitea service"
  echo "  $0 all                    Start all services"
}

if [ $# -lt 1 ] || [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 0
fi

# ensure script is run from its homelab root directory
cd $(dirname "${BASH_SOURCE[0]}") && cd ..
source ./scripts/init.sh

AVAILABLE_SERVICES=$(docker compose config --services)
REQUESTED_SERVICE="$1"

if [ "$REQUESTED_SERVICE" = "all" ]; then
  docker compose up -d
  exit 0
fi

# Service Validation
if ! echo "$AVAILABLE_SERVICES" | grep -q "^$REQUESTED_SERVICE$"; then
  echo "Error: Service '$1' not found."
  echo
  usage
  exit 1
fi

echo "Running docker compose up -d $REQUESTED_SERVICE"

docker compose up -d "$REQUESTED_SERVICE"
