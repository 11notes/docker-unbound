${{ content_synopsis }} Run Unbound distroless and rootless for maximum security.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is automatically scanned for CVEs before and after publishing
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_config }}
```yaml
${{ include: ./rootfs/unbound/etc/default.conf }}
```

The default config gets you started easily and is meant if you use unbound as a local resolver, meaning your unbound will not send DNS queries to 3rd party resolvers like Google or Quad9. If you want to send your queries to these resolvers via DoH/DoT make sure you add the following to your configuration:

```yaml
server:
  tls-upstream: yes
  tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt
```

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of your configuration

${{ content_compose }}

${{ content_defaults }}

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}