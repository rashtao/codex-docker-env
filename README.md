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
  -v "$PWD:/workspace" \
  -w /workspace \
  fedora-codex
```

To use the host Docker daemon, also mount its socket. At startup the image
adds `codex` to the socket's numeric group, so no root shell is needed:

```sh
docker run --rm -it \
  -v "$PWD:/workspace" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w /workspace \
  fedora-codex
```

Mounting the Docker socket gives the container powerful control over the host
Docker daemon; use it only with images and workloads you trust.

## Authenticate Codex at runtime

Provide an API key directly:

```sh
docker run --rm -it -e OPENAI_API_KEY fedora-codex codex --help
```

Or mount an existing Codex configuration directory:

```sh
docker run --rm -it \
  -v "$HOME/.codex:/home/codex/.codex" \
  fedora-codex codex --help
```

Run Codex with its full-permission mode only when you intentionally want it:

```sh
docker run --rm -it -e OPENAI_API_KEY fedora-codex codex -y "your prompt"
```

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
