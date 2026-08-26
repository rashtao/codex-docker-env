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
  -v "$HOME/.codex/auth.json:/home/codex/.codex/auth.json:z" \
  -v "$PWD:/workspace:Z" \
  -w /workspace \
  fedora-codex
```

When `docker` is Podman's Docker-compatible CLI on Fedora, `--userns=keep-id`
maps the invoking host user to the image's `codex` user (UID/GID 1000). This
keeps bind-mounted files owned by `codex` in the container instead of mapping
them to `root`. The option is Podman-specific.

To use a host Docker daemon, also mount its socket. At startup the image adds
`codex` to the socket's numeric group, so no root shell is needed:

```sh
docker run --rm -it \
  --userns=keep-id:uid=1000,gid=1000 \
  -v "$HOME/.codex/auth.json:/home/codex/.codex/auth.json:z" \
  -v "$PWD:/workspace:Z" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w /workspace \
  fedora-codex
```

Mounting the Docker socket gives the container powerful control over the host
Docker daemon; use it only with images and workloads you trust.

### Podman socket access

Do not mount `/var/run/docker.sock` from a rootless Podman invocation when it
points at the system Podman service (`/run/podman/podman.sock`). Rootless
Podman must be able to traverse the source path *before the container starts*;
the system service directory is normally root-only, so the mount fails with
`statfs /var/run/docker.sock: permission denied`. No image entrypoint can
repair that host-side permission check.

Use the invoking user's Podman API socket instead. Enable it once, then mount
it at Docker's conventional path inside the container:

```sh
systemctl --user enable --now podman.socket

docker run --rm -it \
  --userns=keep-id:uid=1000,gid=1000 \
  --security-opt label=disable \
  -v "$HOME/.codex/auth.json:/home/codex/.codex/auth.json:z" \
  -v "$PWD:/workspace:Z" \
  -v "$XDG_RUNTIME_DIR/podman/podman.sock:/var/run/docker.sock" \
  -w /workspace \
  fedora-codex
```

Here `docker` may be Podman's Docker-compatible CLI; the `docker-cli` inside
the image talks to the mounted Podman API socket. `--security-opt label=disable`
is needed because the Podman API socket is not suitable for relabeling with
`:Z`. The compatibility warning (`Emulate Docker CLI using podman`) comes from
the host CLI. To silence it on the host, create `/etc/containers/nodocker` as
an administrator.

If access to an actual rootful Docker socket is required instead, grant the
host user access to that socket first (usually by joining its `docker` group
and starting a new login session). With rootless Podman, also add
`--group-add keep-groups` to preserve that host supplementary group in the
container. This is Podman-specific and must not be used with Docker Engine.

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
