# Headless sway and eww with both backends (X11 and Wayland), for
# test/eww-sway/test.sh. Tag: dotfiles-eww-sway. EWW_REF from bootstrap.sh.
FROM fedora:45

RUN dnf install -y -q --setopt=install_weak_deps=False \
        sway jq procps-ng util-linux coreutils dbus-daemon dejavu-sans-fonts \
    && dnf clean all

# Build tools go after the build: the image is only for the test.
ARG EWW_REF
RUN dnf install -y -q --setopt=install_weak_deps=False \
        rust cargo gcc pkgconf-pkg-config git-core \
        gtk3-devel gtk-layer-shell-devel libdbusmenu-gtk3-devel \
    && cargo install -q --locked --git https://github.com/elkowar/eww --rev "$EWW_REF" \
        --root /usr/local eww \
    && rm -rf /root/.cargo \
    && dnf clean all

RUN useradd -m t && install -d -m 0700 -o t /tmp/xdg-t

# test.sh rebuilds the image when bootstrap.sh pins another commit.
LABEL eww-ref=$EWW_REF
