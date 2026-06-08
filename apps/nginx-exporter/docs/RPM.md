# RPM package requirement

The image expects the exporter to be available from the NiceOS.Container RPM repositories.

Recommended package name:

```text
nginx-prometheus-exporter
```

Required installed payload:

```text
/usr/bin/nginx-prometheus-exporter
```

The image build then creates:

```text
/opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter -> /usr/bin/nginx-prometheus-exporter
/usr/bin/exporter -> /opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter
```

## Optional spec example

A starter RPM spec is included under:

```text
packaging/rpm/nginx-prometheus-exporter.spec
```

Move it to the proper NiceOS.Container RPM repository, for example:

```text
niceos-container-rpms/rpm-nginx-prometheus-exporter
```

Do not treat the app repository as the long-term RPM source of truth. The app repository should consume RPMs from the Container stream.
