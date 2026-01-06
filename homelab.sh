#!/usr/bin/env bash
set -e

usage() {
  echo "Usage:"
  echo "  $0 init                 Initialize the homelab environment"
  echo "  $0 uninstall            Uninstall the homelab environment"
  echo "  $0 list                 List available services"
  echo "  $0 start <service>      Start a single service"
  echo "  $0 start all            Start all services"
  echo
  echo "Examples:"
  echo "  $0 init                 Initialize the homelab environment"
  echo "  $0 uninstall            Uninstall the homelab environment"
  echo "  $0 list                 List available services"
  echo "  $0 start gitea          Start the gitea service"
  echo "  $0 start all            Start all services"
}

# No args
if [ $# -lt 1 ]; then
  usage
  exit 1
fi


if [[ "$1" = "help" || "$1" = "--help" || "$1" = "-h" ]]; then
  usage
  exit 0
fi

if [[ "$1" = "list" || "$1" = "--list" || "$1" = "-l" ]]; then
  echo "Available services:"
  echo "$AVAILABLE_SERVICES"
  exit 0
fi

if [[ "$1" = "init" || "$1" = "--init" || "$1" = "-i" ]]; then
  shift
  source ./scripts/init.sh
  exit 0
fi

if [[ "$1" = "start" || "$1" = "--start" || "$1" = "-s" ]]; then
  shift
  source ./scripts/start-services.sh "$@"
  exit 0
fi

if [[ "$1" = "clean" || "$1" = "--clean" || "$1" = "-c" ]]; then
  shift
  source ./scripts/clean.sh "$@"
  exit 0
fi

if [[ "$1" = "uninstall" || "$1" = "--uninstall" || "$1" = "-u" ]]; then
  shift
  source ./scripts/uninstall-homelab.sh
  exit 0
fi

echo "Error: Unknown command '$1'."
usage
exit 1
