# Security notes

## Runtime posture

The image is designed to run:

- as non-root UID `1001`;
- with arbitrary UID where Kubernetes assigns a random UID;
- with `readOnlyRootFilesystem: true`;
- with all Linux capabilities dropped;
- without package managers in the final image;
- without compiler/build tools in the final image;
- without systemd or sshd.

Example hardened run:

```console
podman run --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev \
  --tmpfs /var/tmp:rw,nosuid,nodev \
  -p 9113:9113 \
  docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1 \
  --nginx.scrape-uri=http://127.0.0.1:8080/status
```

## Network behavior

The exporter opens an HTTP metrics endpoint on port `9113` and scrapes the configured NGINX endpoint. It does not need privileged ports.

## Sensitive data

Do not put secrets into command-line flags. If TLS client credentials are needed, mount them read-only and reference the mounted paths with exporter flags.
