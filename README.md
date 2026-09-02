# Fedora Codex Docker image

An empty-project development image based on `fedora:latest`.  It starts an
interactive Bash shell as the unprivileged `codex` user and includes Docker
CLI, Node.js/npm, the OpenAI Codex CLI, the OpenSpec CLI, SDKMAN, and Temurin
JDKs 8, 21, and 25.
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
  -v "$HOME/.codex/auth.json:/home/codex/.codex/auth.json:z" \
  -v "$HOME/.m2:/home/codex/.m2:z" \
  -v "$PWD:/workspace:Z" \
  -w /workspace \
  fedora-codex
```

To use a host Docker daemon, also mount its socket. At startup the image adds
`codex` to the socket's numeric group, so no root shell is needed:

```sh
docker run --rm -it \
  --security-opt label=disable \
  -v "$HOME/.codex/auth.json:/home/codex/.codex/auth.json:z" \
  -v "$HOME/.m2:/home/codex/.m2:z" \
  -v "$PWD:/workspace:Z" \
  -v /var/run/docker.sock:/var/run/docker.sock:z \
  -w /workspace \
  fedora-codex
```

## Quick checks

Inside the container:

```sh
docker --version
npm --version
codex --version
openspec --version
npm config get prefix
sdk version
sdk list java | grep -i temurin
java -version
```

`npm config get prefix` should be `/home/codex/.npm-global`, and `java -version`
should report the Java 21 Temurin default.
