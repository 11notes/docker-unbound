![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# UNBOUND
![size](https://img.shields.io/docker/image-size/11notes/unbound/1.23.1?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/unbound/1.23.1?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/unbound?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-UNBOUND?color=7842f5">](https://github.com/11notes/docker-UNBOUND/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run unbound rootless, distroless and secure by default!

# INTRODUCTION 📢

Unbound is a validating, recursive, caching DNS resolver. It is designed to be fast and lean and incorporates modern features based on open standards.

# SYNOPSIS 📖
**What can I do with this?** Run Unbound distroless and rootless for maximum security.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/unbound:1.23.1 | 6MB | 1000:1000 | ✅ | amd64, arm64 |
| klutchell/unbound | 14MB | 1000:1000 | ✅ | amd64, armv7, armv6, arm64 |

# VOLUMES 📁
* **/unbound/etc** - Directory of your configuration

# COMPOSE ✂️
```yaml
name: "dns"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  redis:
    image: "11notes/redis:7.4.5"
    <<: *lockdown
    environment:
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    networks:
      backend:
    volumes:
      - "redis.etc:/redis/etc"
      - "redis.var:/redis/var"
    tmpfs:
      - "/run:uid=1000,gid=1000"
    restart: "always"

  unbound:
    depends_on:
      redis:
        condition: "service_healthy"
        restart: true
    image: "11notes/unbound:1.23.1"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
    volumes:
      - "unbound.etc:/unbound/etc"
    ports:
      - "53:53/udp"
      - "53:53/tcp"
    networks:
      frontend:
      backend:
    sysctls:
      net.ipv4.ip_unprivileged_port_start: 53
    restart: "always"

  # ╔═════════════════════════════════════════════════════╗
  # ║     DEMO CONTAINER - DO NOT USE IN PRODUCTION!      ║
  # ╚═════════════════════════════════════════════════════╝
  # used to view the redis database
  demo-redis-gui:
    image: "redis/redisinsight"
    environment:
      RI_REDIS_HOST0: "redis"
      RI_REDIS_PASSWORD0: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    ports:
      - "3000:5540/tcp"
    networks:
      frontend:
      backend:

  # ╔═════════════════════════════════════════════════════╗
  # ║     DEMO CONTAINER - DO NOT USE IN PRODUCTION!      ║
  # ╚═════════════════════════════════════════════════════╝
  # used to generate 100k DNS queries
  dnspyre:
    depends_on:
      unbound:
        condition: "service_healthy"
        restart: true
    image: "11notes/distroless:dnspyre"
    command: "--server unbound -c 10 -n 3 -t A --prometheus ':3000' https://raw.githubusercontent.com/11notes/static/refs/heads/main/src/benchmarks/dns/fqdn/10000"
    read_only: true
    environment:
      TZ: "Europe/Zurich"
    networks:
      frontend:

volumes:
  redis.etc:
  redis.var:
  unbound.etc:

networks:
  frontend:
  backend:
    internal: true
```

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /unbound | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [1.23.1](https://hub.docker.com/r/11notes/unbound/tags?name=1.23.1)

### There is no latest tag, what am I supposed to do about updates?
It is of my opinion that the ```:latest``` tag is dangerous. Many times, I’ve introduced **breaking** changes to my images. This would have messed up everything for some people. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:1.23.1``` you can use ```:1``` or ```:1.23```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/unbound:1.23.1
docker pull ghcr.io/11notes/unbound:1.23.1
docker pull quay.io/11notes/unbound:1.23.1
```

# SOURCE 💾
* [11notes/unbound](https://github.com/11notes/docker-UNBOUND)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless](https://github.com/11notes/docker-distroless/blob/master/arch.dockerfile) - contains users, timezones and Root CA certificates
>* [11notes/distroless:dnslookup](https://github.com/11notes/docker-distroless/blob/master/dnslookup.dockerfile) - app to execute DNS lookups

# BUILT WITH 🧰
* [unbound](https://github.com/NLnetLabs/unbound)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-unbound/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-unbound/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-unbound/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 20.08.2025, 01:58:31 (CET)*