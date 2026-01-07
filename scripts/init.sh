#!/usr/bin/env bash

if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Description:"
  echo "  Initialize the homelab environment by setting up necessary Docker networks."
  echo
  echo "Usage:"
  echo "  $0 init     Initialize the homelab environment"
  echo
  echo "Examples:"
  echo "  $0 init     Initialize the homelab environment"
  exit 0
fi

# ensure script is run from its homelab root directory
cd $(dirname "${BASH_SOURCE[0]}") && cd ..

# start traefik-proxy network if it doesn't exist
if ! docker network ls --format '{{.Name}}' | grep -q "^traefik-proxy$"; then
  echo "Creating traefik-proxy network..."
  docker network create traefik-proxy
fi

# Check if the user wants to use basic auth or Authentik
source .env
if [ $USE_BASIC_AUTH = "false" ]; then
  exit 0;
fi

CREDENTIALS_FILE="./traefik/config/conf/.htpasswd"

# create credentials for traefik dashboard if they don't exist
if [ ! -f "$CREDENTIALS_FILE" ] || [ ! -s "$CREDENTIALS_FILE" ]; then
  if [ ! -f "$CREDENTIALS_FILE" ]; then
    touch "$CREDENTIALS_FILE"
  fi

  echo "Creating credentials for Traefik dashboard..."
  read -r -p "Username: " USERNAME
  read -r -s -p "Password: " PASSWORD

  if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "Username and password cannot be empty."
    exit 1
  fi

  # Try to create the .htpasswd file
  # provide instructions if htpasswd is not installed
  {
    htpasswd -bc "$CREDENTIALS_FILE" "${USERNAME}" "${PASSWORD}"
    echo "Credentials for Traefik dashboard created successfully."
  } || {
    echo "Failed to create credentials for Traefik dashboard. Please ensure 'htpasswd' is installed."
    OS_NAME=$(uname -s)

    case "$OS_NAME" in
      Linux*)
        echo "Install 'htpasswd' by installing the 'apache2-utils' package. (sudo apt install apache2-utils)"
        ;;
      Darwin*)
        echo "Install 'htpasswd' by installing the 'httpd-tools' package via Homebrew. (brew install httpd-tools)"
        ;;
      *)
        echo "Please refer to your operating system's documentation for installing 'htpasswd'."
        ;;
    esac
    exit 1
  }
fi
