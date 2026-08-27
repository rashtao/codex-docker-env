#!/usr/bin/env bash
set -euo pipefail

image="${1:-fedora-codex}"
test_dir="$(mktemp --directory --tmpdir fedora-codex-mount-test.XXXXXX)"
trap 'rm -rf -- "$test_dir"' EXIT

workspace="$test_dir/workspace"
auth_file="$test_dir/auth.json"
mkdir "$workspace"
printf '{"test":true}\n' > "$auth_file"

docker run --rm \
  -v "$auth_file:/home/codex/.codex/auth.json:Z" \
  -v "$workspace:/workspace:Z" \
  -w /workspace \
  "$image" bash -ceu '
    printf "Container identity: "
    id
    printf "Mounted resource ownership:\n"
    stat --format="%n %u:%g %U:%G" /home/codex/.codex/auth.json /workspace

    printf "Auth file contents: "
    cat /home/codex/.codex/auth.json
    printf "{\"container_write\":true}\n" >> /home/codex/.codex/auth.json

    printf "workspace write from container\n" > /workspace/container-write.txt
    printf "Workspace file contents: "
    cat /workspace/container-write.txt
  '
