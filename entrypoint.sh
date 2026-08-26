#!/usr/bin/env bash
set -euo pipefail

socket=/var/run/docker.sock

# A Docker socket is normally owned by root and a host-specific numeric group.
# Add codex to that group at container start without requiring a matching group
# name in the image.
if [[ -S "$socket" ]]; then
  socket_gid="$(stat --format='%g' "$socket")"
  socket_group="$(getent group "$socket_gid" | cut --delimiter=: --fields=1 || true)"

  if [[ -z "$socket_group" ]]; then
    socket_group="docker-host"
    groupadd --gid "$socket_gid" "$socket_group"
  fi

  usermod --append --groups "$socket_group" codex
fi

# Drop privileges while retaining the image's SDKMAN and npm environment.
# `setpriv --init-groups` reads the supplementary group that may have been
# added for the mounted Docker socket above.
export HOME=/home/codex
export USER=codex
export LOGNAME=codex
exec setpriv --reuid=codex --regid=codex --init-groups -- "$@"
