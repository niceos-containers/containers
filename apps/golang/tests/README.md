# Tests

Use the shell test runner:

```bash
./scripts/test.sh docker.io/niceos/golang:1.26.4-niceos13-r1
```

The tests intentionally run with `podman` by default. Set `CONTAINER_ENGINE=docker` if required:

```bash
CONTAINER_ENGINE=docker ./scripts/test.sh docker.io/niceos/golang:1.26.4-niceos13-r1
```

Important: this is a Golang builder image, so `gcc`, `make`, `pkg-config`, and `git` are allowed and expected. The forbidden final-image tools are package managers: `tdnf`, `dnf`, `yum`, and `rpm` command entry points.
