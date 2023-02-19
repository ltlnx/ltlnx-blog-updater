#!/bin/sh
# ltlnx's blog updater script with comments
# MIT licensed

main() {
    # variables
    # naming scheme: global vars start with v; part of paths have the suffix "name"
    vargs=$(argsparse "$@") || die "Failed to parse arguments"
    vblogname="ltlnx"
    vroot="/home/ltlnx/Documents/Blog"
    vsrcname="src"
    vdstname="pages"
    vstyle="$vroot/style.css"
    vbackupdirname="backup"
    vheadername="header"
    vfootername="footer"
    vreleaseheaderprefix="release-"
    vdotfiles="$vroot/$vsrcname/.files"
    vmdconvcommand="$vroot/md2html"
    which $vmdconvcommand >/dev/null || which pandoc >/dev/null \
        && vmdconvcommand="pandoc -f markdown -t html" \
        || die "Markdown conversion program not found"
    # start profiler
    # PS4='+ $(date "+%s.%N")\011 '
    # exec 3>&2 2>$vroot/profiler/bashstart.$$.log
    # set -x
    # since we are moving residue files into this dir instead of deleting
    # them, the script will create the dir if it doesn't exist to minimize
    # file loss
    mkdir -p "$vroot/$vbackupdirname"
    vcurrentfilelist="$(find_exclusion "$vroot/$vsrcname")"
    vcopylist=""
    vremovelist=""
    visrelease="$(echo $vargs | grep -q "r" && echo "y")"
    test_dirs || die "Required directories do not exist"
    # test if src/.files exists, if not create an empty one for diffing
    test -f $vdotfiles || echo "" > $vdotfiles \
        || die "Failed to create .files"
    # set vheader and vfooter according to whether the user specify to
    # build a release
    if (test "$visrelease" = "y"); then
        vheader="$vroot/$vsrcname/$vreleaseheaderprefix$vheadername"
        vfooter="$vroot/$vsrcname/$vreleaseheaderprefix$vfootername"
        mv $vdotfiles "$vdotfiles.tmp"
        echo "" > $vdotfiles
    else
        vheader="$vroot/$vsrcname/$vheadername"
        vfooter="$vroot/$vsrcname/$vfootername"
        # test if the header or footer changed; if so rebuild the whole thing
        if (test $vheader -nt $vdotfiles || test $vfooter -nt $vdotfiles); then
            echo "" > $vdotfiles
        fi
    fi
    vfulldirlist="$(get_dirs "$vcurrentfilelist" | grep -v "/res")"
    vfdiff=$(diff $vdotfiles <(echo "$vcurrentfilelist"))
    vfold=$(echo -e "$vfdiff" | grep -Po "^< \K.*$")
    vfnew="$(echo -e "$(echo -e "$vfdiff" | grep -Po "^> \K.*$")\n$(find_exclusion "$vroot/$vsrcname" -newer "$vdotfiles")" | grep . | sort -u)"
    # mandate the rebuild of the main index when there are changed files
    # this would stay here until I think of a better algorithm
    if (echo -e "$vfnew\n$vfold" | grep -q "$vroot/$vsrcname"); then
        vdirlist="$vroot/$vsrcname"
    fi
    vdirlist="$vdirlist $(get_dirs "$(cat <(echo -e "$vfnew") <(echo -e "$vfold"))")" \
        || vdirlist="$vfulldirlist"
    # build html files for new or changed markdown files
    if [ "$vfnew" ]; then
        # we're going to build all file indices to make sure indice builds
        # have the correct info, but only build indices for dirs with changed files
        for dir1 in $vfulldirlist; do
            build_fileindex $dir1 > "$dir1/.fileindex"
        done
        for dir2 in $vdirlist; do
            vcopylist="$vcopylist${dir2}/index.html\n"
            build_index $dir2 > "$dir2/index.md"
            mdtohtml "$dir2/index.md" > "$dir2/index.html" || die "Failed to convert $dir2 index to HTML"
        done
        for mdfile in $(echo -e "$vfnew" | grep ".md$"); do
            htmlfilename="$(echo $mdfile | mdfilenametohtml)"
            mdtohtml $mdfile > $htmlfilename || die "Failed to convert $mdfile to HTML"
            vcopylist="$vcopylist$htmlfilename\n"
        done
        vcopylist="$vcopylist$(echo -e "$vfnew" | grep -v ".md$")\n"
    fi
    # remove corresponding html files for removed markdown files
    if [ "$vfold" ]; then
        vremovelist="$vremovelist$(echo -e "$vfold" | srctodst | mdfilenametohtml)\n"
        mv $vremovelist "$vroot/$vbackupdirname"
    fi
    if (test "$vcopylist"); then
        # remove blank lines
        vcopylist="$(echo -e "$vcopylist" | grep '.')"
        get_dirs "$vcopylist" | while read -r i; do
            mkdir -p "$(echo "$i" | srctodst)"
        done
        echo -e "$vcopylist" | sort -u | while read -r i; do
            cp $i "$(echo $i | srctodst)"
        done
        echo -e "$vcopylist" | sort -u | grep ".html" | while read -r i; do
            mv $i "$vroot/$vbackupdirname"
        done
        mv $vdotfiles "$vdotfiles.old"
        echo -e "$vcurrentfilelist" > "$vdotfiles"
        if (test "$visrelease" = "y"); then
            rm "$vdotfiles.tmp" "$vdotfiles"
            cp "$vstyle" "$vroot/$vdstname"
        fi
    else
        echo "No changes."
    fi
    # end profiler
    # set +x
    # exec 2>&3 3>&-
}
die() {
    echo "$1" >&2 && exit 1
}
debug_echo() {
    echo $vargs | grep -q 'v' && echo -e "[debug] $1" >&2
}
argsparse() {
    local args=$(echo "$1" | grep -o "[[:alnum:]]" | sort -u) \
        || die "Failed to parse arguments"
    echo $args | grep -q "h" && print_help && exit 0
    echo $args && return 0 || return 1
}
# for the two find functions we use $@ instead of $1 to preserve arguments
# passed to the function
find_exclusion() {
    find $@ -type f \
        -not -path "*/beta/*" -not -path "*/beta" \
        -not -path "*/.*" -not -name "desc" -not -name "index.md"
}
find_dirs_exclusion() {
    find $@ -type d -mindepth 1 -not -path "*/res/*" -not -path "*/res" -not -path "*/.*"
}
test_dirs() {
    test -d "$vroot/$vsrcname" || return 1
    test -d "$vroot/$vdstname" || return 1
}
get_dirs() {
    echo -e "$1" | rev | cut -d '/' -f 2- | rev | sort -u
}
titlize() {
    read inp
    echo -e "$(echo -e "$inp" | sed 's|\b\(.\)|\u\1|g;s|-| |g')"
}
rmhtmltags() {
    read inp
    echo -e "$(echo -e "$inp" | sed 's|<[^>]*>||g')"
}
srctodst() {
    read inp
    echo -e "$(echo -e "$inp" | sed "s|$vroot/$vsrcname|$vroot/$vdstname|g")"
}
mdfilenametohtml() {
    read inp
    echo -e "$(echo -e "$inp" | grep -Po ".*(?=.md)").html"
}
build_fileindex() {
    cd $1
    debug_echo "Building fileindex for $1"
    local fileindex=""
    for mdfile in \
        $(find $1 -mindepth 1 -maxdepth 1 -path "*.md" -not -name "index.md"); do
        local D=$(cat $mdfile | grep -Po '^[\_]*Last [[:alpha:]]*: \K[^\_]*' \
            || echo "(No date)")
        local T=$(head -n 5 $mdfile | grep -Po "^# \K.*$" | rmhtmltags)
        local P=$(basename $mdfile | mdfilenametohtml | sed "s|^\./||g")
        fileindex="$fileindex- <span class=\"date\">$D</span>[$T]($P)\n"
    done
    test "$fileindex" && echo -e "$fileindex" | sort -r -n
}
build_index() {
    cd $1
    debug_echo "Building index for $1"
    local index="$(cat desc 2>/dev/null)" \
        || index="# $(basename $1 | titlize)\n\nNo description.\n\n---\n"
    for subdir in $(find_dirs_exclusion $1); do
        debug_echo "Creating sub-index for $subdir"
        test -f "$subdir/.fileindex" || continue
        index="$index\n\n### $(basename $subdir | titlize)\n"
        index="$index$(head -n 10 "$subdir/.fileindex" | \
            sed "s|](|]($(basename $subdir)/|g")"
        index="$index$(test $(wc -l < "$subdir/.fileindex") -gt 11 \
            && echo "\n\n[More →]" \
            || echo "\n\n[Dedicated page →]")($(basename $subdir)/index.html)"
    done
    test $(wc -l <.fileindex) -gt 0 &&
        if (echo -e "$index" | tail -n 1 | grep -q "→]"); then
            index="$index\n\n### Other pages"
        else
            index="$index\n\n### All pages"
        fi
    index="$index\n$(cat .fileindex 2>/dev/null)" \
        || debug_echo "No files in directory $1"
    echo -e "$index"
}
gennav() {
    if (echo "$1" | grep -qv "index.md"); then
        dotdot="index.html"
        echo $(echo -e "$(for i in $(echo $1 | rev | cut -d '/' -f 2- | rev | sed "s|$vroot/$vsrcname||" | grep -o "\b[^/]*" | tac); do echo "[$(echo $i | titlize)]($dotdot) >"; dotdot="../$dotdot"; done; echo "[$vblogname]($dotdot) >")" | tac) | $vmdconvcommand
    elif [ "$1" != "$vroot/$vsrcname/index.md" ]; then
        dotdot="../index.html"
        echo $(echo -e "$(for i in $(echo $1 | rev | cut -d '/' -f 3- | rev | sed "s|$vroot/$vsrcname||" | grep -o "\b[^/]*" | tac); do echo "[$(echo $i | titlize)]($dotdot) >"; dotdot="../$dotdot"; done; echo "[$vblogname]($dotdot) >")" | tac; echo "**$(echo $1 | rev | cut -d '/' -f 2 | rev | titlize)**") | $vmdconvcommand
    else
        echo "<p><strong>$vblogname</strong></p>"
    fi
}
text_substitutions() {
    # text subs for every post go here
    cat "$1"
}
mdtohtml() {
    local content=""
    page_title="$(head -n 5 $1 | grep -Po "^# \K.*$" | rmhtmltags)" || return 1
    content="$content$(cat $vheader | sed "s|<title>|<title>$page_title|g")\n" || return 1
    content="$content$(gennav $1)\n" || return 1
    # content="$content$(text_substitutions $1 | pandoc -f markdown -t html)\n" || return 1
    content="$content$(text_substitutions $1 | $vmdconvcommand)\n" || return 1
    content="$content$(cat $vfooter)\n" || return 1
    echo -e "$content" || return 1
}

main "$@"
