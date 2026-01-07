# Homelab for AJax2012

This is the public repository for my homelab. Please note, this is for a small homelab instance, not a production environment. Currently, the services included are:

- [Authentik](https://goauthentik.io/) for SSO.
- [Gitea](https://about.gitea.com/) for code repository
- [n8n](https://n8n.io/) for automated AI workflows
- [Open Web UI](https://openwebui.com/) for local ChatGPT replacement
- [portainer](https://www.portainer.io/) for docker dashboard
- [Traefik](https://traefik.io/traefik) for reverse proxy

## Table of Contents

- [Installation](#installation)
- [Customization](#customization)
  - [Disabling Services](#disabling-services)
  - [Creating New Services](#creating-new-services)
- [Using Authentik as an Auth Provider](#using-authentik-as-an-auth-provider)
  - [Open WebUI with Authentik](#open-webui-with-authentik)
  - [Traefik Dashboard: Migrating from Basic Auth to Authentik](#traefik-dashboard-migrating-from-basic-auth-to-authentik)
- [Basic Troubleshooting](#basic-troubleshooting)
- [Future Plans](#future-plans)
- [Uninstall](#uninstall)

## Installation

NOTE: This has only been tested on ubuntu server.

1. Clone the repository (will update after deployment)
2. Navigate to each `.env.example`, remove `.example` from the file name and fill out the required values.
    - NOTE: If you want to use Authentik auth for the traefik dashboard and you don't want to bother with using basic auth, set `USE_BASIC_AUTH` to `false` in the [global .env file](./.env.example)
3. From the root directory, run `./homelab.sh init`
    - The terminal will prompt you to fill out a username and password for authenticating the traefik dashboard. The password will be hashed. If you don't want this, comment out the following:
      - everything below the variable `CREDENTIALS_FILE` section in the [init script](./scripts/init.sh), then
      - the traefik auths middleware block in the [traefik middleware config](./traefik/config/conf/middlewares.yaml)
      - `- "traefik.http.routers.traefik.middlewares=traefik-auth@file"` in the [traefik compose file](./traefik/compose.yaml)
    - Review the notes in the api section of the [traefik configuration](./traefik/config/traefik.yaml).
4. run `docker compose up -d` from the root folder.
    - if you want to run single services (along with traefik), run `./homelab.sh start <service>`.
    - If you want to know more about the [homelab.sh](./homelab.sh) tool, you can run `./homelab.sh -h` to get the help dialogue.

## Customization

You can remove services from this without needing to delete the folder. At the moment, you'll need to re-disable the services whenever there is an update though.

### Disabling Services

If you want to remove some of the services in my configuration, you can just go to [docker-compose.yaml](./docker-compose.yaml) and comment out or delete the file you don't want in the `include` section and the service you don't want in the `service` section.

### Creating New Services

If you want to add a new service to my homelab setup:

1. Create a new directory.
2. Add a `compose.yaml` (or docker-compose.yaml, compose.yml, etc.) to the new directory.
3. Add a `.env` file with a minimum of `SUBDOMAIN`
4. To use Traefik, add the following to your `compose.yaml` file and fill out the remainder of the required information for your docker compose file:

```yaml
services:
  <serviceName>
    image: <image>
    container_name: <serviceName>
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - traefik-proxy
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik-proxy"
      - "traefik.http.routers.<serviceName>.rule=Host(`${SUBDOMAIN:-<serviceName>}.${DOMAIN_NAME}`)"
      - "traefik.http.routers.<serviceName>.entrypoints=websecure"
      - "traefik.http.routers.<serviceName>.tls=true"
      - "traefik.http.routers.<serviceName>.tls.certresolver=cloudflare"
      - "traefik.http.services.<serviceName>.loadbalancer.server.port=9000"

networks:
  traefik-proxy:
    external: true
```

## Using Authentik as an Auth Provider

[Authentik](https://goauthentik.io/) allows you to set up SSO for your applications. Gitea, Open WebUI, and Portainer could all be set up using Open ID Connect (OIDC). Their [Integrations](https://integrations.goauthentik.io/) documentation is very thorough and should be fairly easy to follow. I had to set up the Traefik Dashboard as a [forwardAuth](https://docs.goauthentik.io/add-secure-apps/providers/proxy/server_traefik/) provider, which means it requires a little more setup before you can get it working. See the section below for more details.

### Open WebUI with Authentik

This is explained in the documentation, but this is set up in the Open WebUI's [.env](./open-webui/.env.example) file rather than in the application UI, like most other applications. Once you update the environment variables, restart Open WebUI's docker container and it will be behind the Authentik auth provider.

### Traefik Dashboard: Migrating from Basic Auth to Authentik

If you follow Authentik's documentation, the process for setting up forwardAuth for an application is fairly simple, but it might be a little confusing to see the dashboard not working if you try to run that before the setup is complete. I have [basicAuth](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/basicauth/) set up by default for the traefik dashboard to help make it a bit easier.

In order to migrate your traefik dashboard from basicAuth to forwardAuth, do the following:

1. Set up your Proxy Provider (Forward auth (single application) with explicit authorization flow) and application in the Authentik dashboard.
2. Edit the created Outpost and set your new application as one of the Selected Applications.
3. Edit the traefik [.env](./traefik/.env.example) and set `DASHBOARD_AUTH_PROVIDER` to `authentik`.
4. Restart the traefik container.

You should now see the traefik dashboard protected by Authentik rather than username/password.

## Future Plans

I plan on adding the following services in the future. I'm not sure beyond that.

- [Grafana](https://grafana.com/) for more advanced container troubleshooting.
- Centralized logging.
- A full dashboard for navigating.

I would also like to make future improvements for ease of use:

- Allow a user to retain their [docker-compose.yaml](./docker-compose.yaml) file rather than having it overridden every time I make an update
- Add a script for generating a folder
- Either Kubernetes or Docker Swarm (I'm currently leaning toward swarm, since it's for a small homelab, not a production environment.)
- Add a folder for personal projects (So I don't share my private projects with everyone on GitHub).
- Automate pulling git when changes occur (or displaying a popup/toast somewhere indicating there's an update).

For now though, I'm going to take a break on this project and come back to it. Originally, this was just a project for myself. Then I decided to get something basic set up for a colleague, but I went a little overboard for what I had planned.

## Basic Troubleshooting

If you're having trouble with getting Traefik to work, I would recommend changing the log level to DEBUG in the [traefik.yaml](./traefik/config/traefik.yaml) file. Otherwise, run `docker logs <service>`. If you're really stuck, remove the volumes and networks for a specific docker container by running `./homelab.sh clean <service>` and follow the prompts. That will start you off with a clean volume, network, and docker container.

## Uninstall

To completely remove my homelab from your server, run `./homelab.sh uninstall`. This will automatically do the following:

1. Remove your docker containers
2. Clean your volumes and networks
3. Remove the traefik proxy network
4. After confirming, it can remove the homelab folder for you.
