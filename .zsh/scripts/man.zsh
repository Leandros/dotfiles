# Man functions

# Open man pages in Preview.app on OS X
if [[ "Darwin" == "`uname`" ]]; then
    man-preview () {
        man -t "$@" | open -f -a /Applications/Preview.app
    }
    alias pman='man-preview'
fi

# Convert man page to pdf
man-pdf () {
    man -t "$@" | pstopdf -i -o "$@.pdf"
}

# Colorized man
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            man "$@"
}

