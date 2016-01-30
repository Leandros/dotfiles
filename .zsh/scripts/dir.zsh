# Directory listing functions

duf () {
    du -sk "$@" | sort -n | \
        while read size fname
            do for unit in k M G T P E Z Y
                do if [ $size -lt 1024 ]; then
                    echo -e "${size}${unit}\t${fname}"
                    break
                fi
            size=$((size/1024))
            done
        done
}
dirsize () {
    du -shx * .[a-zA-Z0-9_]* 2> /dev/null | \
    egrep '^ *[0-9.]*[MG]' | sort -n > /tmp/list
    egrep '^ *[0-9.]*M' /tmp/list
    egrep '^ *[0-9.]*G' /tmp/list
    rm -rf /tmp/list
}

