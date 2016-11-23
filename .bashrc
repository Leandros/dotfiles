
# Source Perforce, if any processes end up using bash instead of zsh.
if [ -f "$HOME/.p4creds" ]; then
    source "$HOME/.p4creds"
fi

