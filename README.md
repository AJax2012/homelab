# Homelab for AJax2012

This is the public repository for my homelab. Please note, this is for a small homelab instance, not a production environment. Currently, the services included are:

- [Authentik](https://goauthentik.io/) for SSO.
- [Dockhand](https://dockhand.pro/) for in-depth docker container management
- [Gitea](https://about.gitea.com/) for code repository
- [Grafana](https://grafana.com/) for monitoring and log visualization
- [Homebridge](https://homebridge.io/) for Apple Home integrations with HomeKit
- [Homepage](https://gethomepage.dev/) for Homelab dashboard
- [n8n](https://n8n.io/) for automated AI workflows
- [Open Web UI](https://openwebui.com/) for local ChatGPT replacement
- [Pi-hole](https://pi-hole.net/) for local DNS and DNS forwarding
- [Portainer](https://www.portainer.io/) for docker dashboard
- [Traefik](https://traefik.io/traefik) for reverse proxy

## Table of Contents

- [Installation](#installation)
  - [Dockhand](#dockhand)
  - [Setting up Pi-hole](#setting-up-pi-hole)
- [Customization](#customization)
  - [Disabling Services](#disabling-services)
  - [Creating New Services](#creating-new-services)
- [Using Authentik as an Auth Provider](#using-authentik-as-an-auth-provider)
  - [Grafana with Authentik](#grafana-with-authentik)
  - [Open WebUI with Authentik](#open-webui-with-authentik)
  - [Traefik Dashboard: Migrating from Basic Auth to Authentik](#traefik-dashboard-migrating-from-basic-auth-to-authentik)
- [Basic Troubleshooting](#basic-troubleshooting)
- [Homepage Dashboard Setup](#homepage-dashboard-setup)
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

### Dockhand

A few important things to note about [Dockhand](https://dockhand.pro/) - it gives anyone who has access to it a *lot* of power over your docker containers. I would highly recommend locking this down with Authentik SSO before most other applications and disallowing user sign-up. In return though, you get docker container scanning, automatic updates, alerts, etc. It's a great tool for a docker power user.

### Setting up Pi-hole

Unfortunately, this part is more dependant on your network configuration than anything else, which is why I didn't include it in the [network's compose.yaml](./networking/compose.yaml) file and set it up so it wouldn't run by default.

1. Create the docker network using the following command:

    ```bash
    docker network create -d macvlan \
      --subnet=<subnet> \
      --gateway=<network-gateway> \
      -o parent=<lan-interface> \
      macvlan_lan
    ```

    - Example values:
      subnet: 192.168.1.0/24
      network-gateway: 192.168.1.1
      lan-interface: enp3s0

2. Update the [networking .env](./networking/.env.example) file with a password and your desired LAN IP address for the Pi-hole application.
3. Uncomment the `NETWORKING_DIRECTORY` variable in the [global .env](./.env.example) file.

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

### Grafana with Authentik

As far as I can tell, users can't sync local user accounts with Grafana, or at least, I couldn't get it to work and I found a few people on different forums having issues with it as well. Once a user is created, it's actually pretty easy to update the OAuth settings, then update the user permissions.

Steps to configure:

1. Follow the instructions [in the documentation](https://integrations.goauthentik.io/monitoring/grafana/#create-an-application-and-provider-in-authentik) to create a provider and application in Authentik for Grafana using OAuth2/OpenID Provider.
2. Setup [.env](./grafana/.env.example) variables:
    - Copy and paste the ClientID and Client Secret.
    - Ensure the other environment variables are correct
3. Start up Grafana using your preferred method.
4. Log into the user interface:
    - Username: "admin"
    - Password: value for `GF_SECURITY_ADMIN_PASSWORD` in the .env file.
5. Navigate to Administration => Authentication => Generic SSO. It should be "enabled".
6. Click "Enter OpenID Connect Discovery Url". Copy and paste the following, but update the variables in `${}`:
    - `https://${AUTHENTIK_SUBDOMAIN}.${DOMAIN_NAME}/application/o/open-web-ui/.well-known/openid-configuration`
7. Under "User Mappings", verify the following are correct. This will allow the admin user to configure users at will rather than auto-syncing roles.
    - Enable "Allow sign up"
    - Disable "Allow assign Grafana Admin"
    - Enable "Skip organization role sync"
8. Logout of admin user
9. Login using Authentik to create the user
10. Logout of new user
11. Navigate to `https://${AUTHENTIK_SUBDOMAIN}.${DOMAIN_NAME}/login?disableAutoLogin`
12. Login with admin user credentials
13. Adjust the new user permissions as needed
14. Logout of admin user
15. Login using Authentik
16. Verify SSO user has correct permissions
17. (Recommended) Disable default admin user

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

## Homepage Dashboard Setup

[Homepage](https://gethomepage.dev/) is a home dashboard for all of your services. I would recommend going through the [config](./homepage/config/) folder to review all of the configurations, though it's easy to update while the docker container is running. For syntax and other help, review [the documentation](https://gethomepage.dev/configs/). A couple of quick notes about the configuration I'm currently syncing:

1. All of the routes are currently found in the [.env](./homepage/.env.example) file so they can be used as variables in the [services.yaml](./homepage/config/services.yaml) file. I would recommend going through the services file to add or remove services that you may not need. for example, I have Home Assistant in there, which I run on a separate computer rather than a docker container on my homelab. If you don't have this, you'll want to remove that from the services file. I also have links to my Synology NAS in there, which you may want to remove.
2. Several of the services in the [services.yaml](./homepage/config/services.yaml) file have auth tokens found in the [.env](./homepage/.env.example) file. You'll need to generate those before they work for you.
3. Latitude and Longitude are included in the [.env](./homepage/.env.example) file for the weather application. If you don't wish to get your location, you can comment them out and use your browser's current location. You will need to accept the popup that results, but it still works great.
4. Since I assume almost everyone downloading this has a [Github](https://github.com) account, I added a bookmark to Github with an env variable to set your account. I also added a couple of other bookmarks. Feel free to remove them in the [bookmarks.yaml](./homepage/config/bookmarks.yaml) file.

## Future Plans

I plan on adding the following services in the future. I'm not sure beyond that.

- Centralized logging.

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
