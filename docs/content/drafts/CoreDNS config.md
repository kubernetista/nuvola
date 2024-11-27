# CoreDNS config for internal DNS resolution in Kubernetes of localtest.me domain

```config
    template IN A {
        match ^(.*)\.localtest\.me\.$
        answer "{{.Name}} 60 IN A 10.43.246.177"
    }

    template IN CNAME {
        match ^(.*)\.localtest\.me\.$
        answer "{{.Name}} 60 IN CNAME traefik.traefik.svc.cluster.local."
    }
```
