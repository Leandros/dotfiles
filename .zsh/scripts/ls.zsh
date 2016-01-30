# File listing

# List files recursively and match a pattern
l() {
  local p=$argv[-1]
  [[ -d $p ]] && { argv[-1]=(); } || p='.'
  find $p ! -type d | sed 's:^./::' | egrep "${@:-.}"
}

# ls on steroids
lr() {
  zparseopts -D -E S=S t=t r=r h=h U=U l=l F=F d=d
  local sort="sort -t/ -k2"                                # by name (default)
  local numfmt="cat"
  local long='s:[^/]* /::; s:^\./\(.\):\1:;'               # strip detail
  local classify=''
  [[ -n $F ]] && classify='/^d/s:$:/:; /^-[^ ]*x/s:$:*:;'  # dir/ binary*
  [[ -n $l ]] && long='s: /\./\(.\): \1:; s: /\(.\): \1:;' # show detail
  [[ -n $S ]] && sort="sort -n -k5"                        # by size
  [[ -n $r ]] && sort+=" -r"                               # reverse
  [[ -n $t ]] && sort="sort -k6" && { [[ -n $r ]] || sort+=" -r" } # by date
  [[ -n $U ]] && sort=cat                                  # no sort, live output
  [[ -n $h ]] && numfmt="numfmt --field=5 --to=iec --padding=6"  # human fmt
  [[ -n $d ]] && set -- "$@" -prune                        # don't enter dirs
  find "$@" -printf "%M %2n %u %g %9s %TY-%Tm-%Td %TH:%TM /%p -> %l\n" |
    $=sort | $=numfmt |
    sed '/^[^l]/s/ -> $//; '$classify' '$long
}
