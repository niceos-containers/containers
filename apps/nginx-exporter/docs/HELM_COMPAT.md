# Helm compatibility

## Target

This image is intended for the metrics sidecar in the NiceOS-adapted `nginx` chart and in historical Bitnami-compatible chart flows.

The chart-level contract is:

```yaml
metrics:
  enabled: true
  image:
    registry: docker.io
    repository: niceos/nginx-exporter
    tag: 1.5.1-niceos13-r1
```

## Why the `exporter` alias matters

The Bitnami NGINX chart starts the metrics sidecar using the `exporter` command. Therefore the image must provide:

```text
/usr/bin/exporter
```

NiceOS implements it as a symlink to:

```text
/opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter
```

## NGINX scrape URI

The chart usually scrapes the NGINX container through loopback inside the same pod:

```text
http://127.0.0.1:8080/status
```

The exporter itself also supports the upstream default:

```text
http://127.0.0.1:8080/stub_status
```

The exact path depends on the NGINX chart configuration. For the NiceOS NGINX chart, keep the metrics status location aligned with chart templates.

## Render-only test

```console
./tests/helm-nginx-chart-metrics-smoke.sh /DATA2/niceos-containers/chart-nginx/chart \
  docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1
```

## Cluster test

Set `NICEOS_HELM_APPLY=1` if you want the test script to install into the current Kubernetes context:

```console
NICEOS_HELM_APPLY=1 \
./tests/helm-nginx-chart-metrics-smoke.sh /DATA2/niceos-containers/chart-nginx/chart \
  docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1
```

The script uses a temporary release name and removes it at the end.
