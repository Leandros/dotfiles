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

# Short of learning how to actually configure OSX, here's a hacky way to use
# GNU manpages for programs that are GNU ones, and fallback to OSX manpages otherwise
# oh, and colorized
alias gnuman='_() { echo $1; man -M $(brew --prefix)/opt/coreutils/libexec/gnuman $1 1>/dev/null 2>&1;  if [ "$?" -eq 0  ]; then man -M $(brew --prefix)/opt/coreutils/libexec/gnuman $1; else man $1; fi  }; _'
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            gnuman "$@"
}

