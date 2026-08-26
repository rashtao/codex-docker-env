# Fedora Codex Docker image

An empty-project development image based on `fedora:latest`.  It starts an
interactive Bash shell as the unprivileged `codex` user and includes Docker
CLI, Node.js/npm, the OpenAI Codex CLI, SDKMAN, and Temurin JDKs 8, 21, and 25.
Java 21 is the SDKMAN default.

## Build

SDKMAN resolves the newest Temurin patch release available at build time. Use
`--no-cache` when rebuilding to refresh those external downloads:

```sh
docker build --pull --no-cache -t fedora-codex .
```

## Run

Open the default Bash shell and mount the current directory as a workspace:

```sh
docker run --rm -it \
  --userns=keep-id:uid=1000,gid=1000 \
  -v "$HOME/.codex/auth.json:/home/codex/.codex/auth.json:Z" \
  -v "$PWD:/workspace:Z" \
  -w /workspace \
  fedora-codex
```

When `docker` is Podman's Docker-compatible CLI on Fedora, `--userns=keep-id`
maps the invoking host user to the image's `codex` user (UID/GID 1000). This
keeps bind-mounted files owned by `codex` in the container instead of mapping
them to `root`. The option is Podman-specific.

To use the host Docker daemon, also mount its socket. At startup the image
adds `codex` to the socket's numeric group, so no root shell is needed:

```sh
docker run --rm -it \
  --userns=keep-id:uid=1000,gid=1000 \
  -v "$HOME/.codex/auth.json:/home/codex/.codex/auth.json:Z" \
  -v "$PWD:/workspace:Z" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w /workspace \
  fedora-codex
```

Mounting the Docker socket gives the container powerful control over the host
Docker daemon; use it only with images and workloads you trust.

## Quick checks

Inside the container:

```sh
docker --version
npm --version
codex --version
npm config get prefix
sdk version
sdk list java | grep -i temurin
java -version
```

`npm config get prefix` should be `/home/codex/.npm-global`, and `java -version`
should report the Java 21 Temurin default.
