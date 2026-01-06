#!/usr/bin/env bash

if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Description:"
  echo "  Uninstall the homelab environment by removing Docker containers, volumes, and networks."
  echo
  echo "Usage:"
  echo "  $0 uninstall            Uninstall the homelab environment"
  echo
  echo "Examples:"
  echo "  $0 uninstall            Uninstall the homelab environment"
  exit 0
fi

read -r -p "Are you sure you want to uninstall the homelab environment? This will remove all Docker containers, volumes, and networks associated with the homelab. This action cannot be undone. (y/N): " CONFIRM_UNINSTALL

if [[ "$CONFIRM_UNINSTALL" != "y" && "$CONFIRM_UNINSTALL" != "Y" ]]; then
  echo "Uninstallation cancelled."
  exit 0
fi

cd $(dirname "${BASH_SOURCE[0]}") && cd ..

echo "Stopping and removing all Docker containers and volumes, and networks associated with the homelab..."
docker compose down
docker compose rm -fv

# remove traefik-proxy network if it exists
if docker network ls --format '{{.Name}}' | grep -q "^traefik-proxy$"; then
  docker network rm traefik-proxy
fi

echo "Homelab docker environment uninstalled successfully."
read -r -p "Would you like to delete the homelab configuration files from this directory? This action cannot be undone. (y/N): " CONFIRM_DELETE_FILES

if [[ "$CONFIRM_DELETE_FILES" = "y" || "$CONFIRM_DELETE_FILES" = "Y" ]]; then
  echo "Deleting homelab configuration files..."
  rm -rf ./*
  echo "Homelab configuration files deleted."
else
  echo "Homelab configuration files retained. You can delete them manually by running 'rm -rf $(pwd)' if desired."
fi
