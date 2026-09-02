FROM fedora:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Keep OS packages in a stable, cacheable layer.  Everything below this point
# that contacts npm or SDKMAN is intentionally isolated in its own layer.
RUN dnf -y upgrade --refresh \
    && dnf -y install \
        bubblewrap \
        ca-certificates \
        curl \
        docker-cli \
        git \
        nodejs \
        npm \
        sudo \
        tar \
        unzip \
        which \
        zip \
        jq \
        python3.13  \
        python3.13-devel \
        gcc \
        gcc-c++ \
        make \
        git \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN useradd --create-home --shell /bin/bash codex \
    && install -d --owner=codex --group=codex /home/codex/.npm-global

ENV SDKMAN_DIR=/home/codex/.sdkman \
    NPM_CONFIG_PREFIX=/home/codex/.npm-global \
    PATH=/home/codex/.npm-global/bin:/home/codex/.sdkman/candidates/java/current/bin:/home/codex/.sdkman/candidates/maven/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

USER codex
WORKDIR /home/codex

# npm is deliberately installed from its upstream registry, rather than a
# Fedora package, so the CLIs follow their current published releases.
RUN npm install --global \
    @openai/codex \
    @fission-ai/openspec@latest

# Resolve identifiers when building, rather than pinning JDK patch releases.
# `sdk list java` is ordered with the newest compatible release first. Each
# external JDK download has its own layer, so a completed download is reusable.
RUN curl --fail --silent --show-error https://get.sdkman.io | bash

# SDKMAN lists Maven releases newest first; select its newest stable 3.x
# candidate at build time rather than pinning an individual release.
RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && candidate="$(sdk list maven | awk '\
      { for (i = 1; i <= NF; i++) { \
          if ($i ~ /^3\.[0-9]+\.[0-9]+$/) { print $i; exit } \
        } }')" \
    && test -n "$candidate" \
    && sdk install maven "$candidate"

RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && candidate="$(sdk list java | awk '\
      { for (i = 1; i <= NF; i++) { \
          if ($i ~ /^8\./ && $i ~ /-tem$/) { print $i; exit } \
        } }')" \
    && test -n "$candidate" \
    && sdk install java "$candidate"

RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && candidate="$(sdk list java | awk '\
      { for (i = 1; i <= NF; i++) { \
          if ($i ~ /^21\./ && $i ~ /-tem$/) { print $i; exit } \
        } }')" \
    && test -n "$candidate" \
    && sdk install java "$candidate"

RUN source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && candidate="$(sdk list java | awk '\
      { for (i = 1; i <= NF; i++) { \
          if ($i ~ /^25\./ && $i ~ /-tem$/) { print $i; exit } \
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
    && printf '%s\n' 'codex ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/codex \
    && chmod 0440 /etc/sudoers.d/codex \
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
