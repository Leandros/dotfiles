dotfiles
========

My dotfiles

### Fonts

All fonts are patched to work with powerline / airline.


### Bootstrap a new machine

Debian 12+, Ubuntu 22.04+, Amazon Linux 2 / 2023 (x86_64, aarch64), macOS (Apple Silicon):

```
curl -fsSL "https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/bootstrap.sh" | bash
```

Installs pinned tool versions to `/usr/local`, clones this repository to
`~/.dotfiles`, and symlinks the configs. Safe to re-run; versions are pinned
at the top of `bootstrap.sh`.

Test in Docker: `test/bootstrap/run.sh [debian12|ubuntu2204|al2|al2023]`.


### Quick Init on ephemeral Linux machines (bash + vim only)

```
curl -SsL "https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master/init.sh" | bash
```
