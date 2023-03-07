# Vaultwarden Docker

[![Push to ghcr.io](https://github.com/yangwu91/vaultwarden-docker/actions/workflows/ghcr-publish.yml/badge.svg)](https://github.com/yangwu91/vaultwarden-docker/actions/workflows/ghcr-publish.yml)

This is a repository of Vaultwarden docker integrated with nginx and frp.

Vaultwarden was folked from `https://github.com/dani-garcia/vaultwarden`

Nginx was folked from `https://github.com/nginx/nginx`

Frp was folked from `https://github.com/fatedier/frp`

## Intro

| Port | Notes                                       | Exposed |
| ---- | ------------------------------------------- | ------- |
| 443  | Vaultwarden w/ ssl reverse proxied by Nginx |   [x]   |
| 80   | Native Vaultwarden w/o ssl                  |   [x]   |
| 8080 | A simple static page to test if Nginx works |   [x]   |
| 4443 | Proxied by Frpc with real IP delivered      |   [ ]   |

## Usage

```bash
# Optional: create a macvlan:
docker network create -d macvlan --gateway 192.168.1.1 --subnet 192.168.1.1/24 --ip-range 192.168.1.64/28 -o parent=eth0 my-macvlan

# Optional: build a image:
docker build -t vaultwarden-customized:latest .

# Run a container on a macvlan network (recommended):
docker run -it -d --privileged --network my-macvlan --ip 192.168.1.2 -v /host-data:/data -v /host-log:/log -v /host-ssl:/ssl:ro -v /host-nginx-conf:/nginx-conf -v /host-frp/frpc.ini:/frp/frpc.ini --env "LOG_FILE=/log/bitwarden.log" --env "TZ=Asia/Hong_Kong" --env "WEBSOCKET_ENABLED=true" --env "SIGNUPS_ALLOWED=false" --env "FULLCHAIN=/ssl/my_fullchain.cer" --env "PRIVATE=/ssl/my_website.key" --env "ADMIN_TOKEN=XXXX" vaultwarden-customized:latest

# Run a container on a bridge network:
docker run -it -d --privileged --network bridge -p 9080:8080 -p 9081:80 -p 9082:443 -v /host-data:/data -v /host-log:/log -v /host-ssl:/ssl:ro -v /host-nginx-conf:/nginx-conf -v /host-frp/frpc.ini:/frp/frpc.ini --env "LOG_FILE=/log/bitwarden.log" --env "TZ=Asia/Hong_Kong" --env "WEBSOCKET_ENABLED=true" --env "SIGNUPS_ALLOWED=false" --env "FULLCHAIN=/ssl/my_fullchain.cer" --env "PRIVATE=/ssl/my_website.key" --env "ADMIN_TOKEN=XXXX" vaultwarden-customized:latest
```

