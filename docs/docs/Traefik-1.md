
### Option 2: update Traefik and make it use the mkcert custom CA

_(Option 1 is in the [Quick Start](/Quick-Start))_

Reference:

- How to do it with Docker compose:
      - <https://medium.com/@clintcolding/use-your-own-certificates-with-traefik-a31d785a6441>

Relevant part of the Helm values:

```yaml
# -- Add volumes to the traefik pod. The volume name will be passed to tpl.
# This can be used to mount a cert pair or a configmap that holds a config.toml file.
# After the volume has been mounted, add the configs into traefik by using the `additionalArguments` list below, eg:
`additionalArguments:
- "--providers.file.filename=/config/dynamic.toml"
# - "--ping"
# - "--ping.entrypoint=web"`
volumes:
- name: public-cert
  mountPath: "/certs"
  type: secret
- name: '{{ printf "%s-configs" .Release.Name }}'
  mountPath: "/config"
  type: configMap
```
