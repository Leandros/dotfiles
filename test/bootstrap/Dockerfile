# Minimal image: a non-root user with passwordless sudo, nothing else.
# bootstrap.sh must install everything it needs.
ARG BASE
FROM ${BASE}

ARG PKG_CMD
RUN eval "$PKG_CMD"

RUN useradd -m -s /bin/bash arvid \
    && echo 'arvid ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/arvid \
    && chmod 0440 /etc/sudoers.d/arvid

# Simulate damage from an earlier "sudo nvim": root-owned dirs in HOME.
RUN mkdir -p /home/arvid/.local/state/nvim \
    && chown -R root:arvid /home/arvid/.local

USER arvid
WORKDIR /home/arvid
ENV HOME=/home/arvid USER=arvid
