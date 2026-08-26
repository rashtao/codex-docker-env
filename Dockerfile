FROM fedora:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Keep OS packages in a stable, cacheable layer.  Everything below this point
# that contacts npm or SDKMAN is intentionally isolated in its own layer.
RUN dnf -y upgrade --refresh \
    && dnf -y install \
        ca-certificates \
        curl \
        docker-cli \
        nodejs \
        npm \
        tar \
        unzip \
        which \
        zip \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN useradd --create-home --shell /bin/bash codex \
    && install -d --owner=codex --group=codex /home/codex/.npm-global

ENV SDKMAN_DIR=/home/codex/.sdkman \
    NPM_CONFIG_PREFIX=/home/codex/.npm-global \
    PATH=/home/codex/.npm-global/bin:/home/codex/.sdkman/candidates/java/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

USER codex
WORKDIR /home/codex

# npm is deliberately installed from its upstream registry, rather than a
# Fedora package, so `codex` follows the current published CLI release.
RUN npm install --global @openai/codex

# Resolve identifiers when building, rather than pinning JDK patch releases.
# `sdk list java` is ordered with the newest compatible release first. Each
# external JDK download has its own layer, so a completed download is reusable.
RUN curl --fail --silent --show-error https://get.sdkman.io | bash

RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && candidate="$(sdk list java | awk -F'|' '\
      { for (i = 1; i <= NF; i++) { \
          item = $i; \
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", item); \
          if (item ~ /^8\./ && item ~ /-tem$/) { print item; exit } \
        } }')" \
    && test -n "$candidate" \
    && sdk install java "$candidate"

RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && candidate="$(sdk list java | awk -F'|' '\
      { for (i = 1; i <= NF; i++) { \
          item = $i; \
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", item); \
          if (item ~ /^21\./ && item ~ /-tem$/) { print item; exit } \
        } }')" \
    && test -n "$candidate" \
    && sdk install java "$candidate"

RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && candidate="$(sdk list java | awk -F'|' '\
      { for (i = 1; i <= NF; i++) { \
          item = $i; \
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", item); \
          if (item ~ /^25\./ && item ~ /-tem$/) { print item; exit } \
        } }')" \
    && test -n "$candidate" \
    && sdk install java "$candidate"

RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && java_21="$(find "$SDKMAN_DIR/candidates/java" -maxdepth 1 -type d -name '21.*-tem' -printf '%f\n' | head -n 1)" \
    && test -n "$java_21" \
    && sdk default java "$java_21"

USER root
COPY entrypoint.sh /usr/local/bin/codex-entrypoint
RUN install -d --owner=codex --group=codex --mode=0700 /home/codex/.codex \
    && printf '%s\n' \
        'sandbox_mode = "danger-full-access"' \
        'approval_policy = "never"' \
        'model = "gpt-5.6-terra"' \
        'model_reasoning_effort = "medium"' \
        '' \
        '[features]' \
        'fast_mode = false' \
        '' \
        '[tui]' \
        'status_line = ["model-with-reasoning", "run-state", "context-remaining", "five-hour-limit", "weekly-limit", "context-window-size", "total-input-tokens", "total-output-tokens", "task-progress", "approval-mode"]' \
        > /home/codex/.codex/config.toml \
    && chown codex:codex /home/codex/.codex/config.toml \
    && chmod 0600 /home/codex/.codex/config.toml \
    && chmod 0755 /usr/local/bin/codex-entrypoint

ENTRYPOINT ["/usr/local/bin/codex-entrypoint"]
CMD ["bash"]
