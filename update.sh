#!/bin/sh
# ltlnx's blog updater script with comments
# MIT licensed

main() {
    vargs=$(argsparse "$@") || die "Failed to parse arguments"
    # test if a config is present in the same dir as the update script
    # if not write an example config to the same directory as the script
    vconfigname="updater_config"
    vconfig=$(echo "$0" | sed "s|$(basename "$0")|$vconfigname|")
    test -f "$vconfig" && source "$vconfig" || script_init
    test_result="$(run_tests)"
    test -z "$test_result" || die "$test_result"
    # quick commands
    case $1 in
        deploy)
            test "$2" || die "Please input a commit message"
            test "$3" && die "Please put the commit message in quotes"
            cd "$vroot"/"$vdstname" || exit 1
            git add .
            git commit -m "$2"
            git push
            cd - || exit 1
            exit 0
            ;;
        serve)
            cd "$vroot"/"$vdstname" || exit 1
            python3 -m http.server || die "Your system probably does not have Python 3 installed. Please change the line invoking python3 into your own web server command, or install Python 3."
            cd - || exit 1
            exit 0
            ;;
    esac
    vdotfiles="$vroot/.files"
    # start profiler if variable is set
    if (echo "$vargs" | grep -q 'p'); then
        PS4='+ $(date "+%s.%N")\011 '
        mkdir -p "$vroot"/profiler
        exec 3>&2 2>"$vroot"/profiler/bashstart.$$.log
        set -x
    fi
    vcurrentfilelist="$(find_exclusion "$vroot/$vsrcname")"
    vcopylist=""
    vremovelist=""
    vresiduefilelist=""
    # test if src/.files exists, if not create an empty one for diffing
    test -f "$vdotfiles" || echo "" > "$vdotfiles" \
        || die "Failed to create .files"
    cp "$vdotfiles" "$vdotfiles.old"
    vheader="$vroot/$vheadername"
    vfooter="$vroot/$vfootername"
    # test if the header or footer changed; if so rebuild the whole thing
    if test "$vheader" -nt "$vdotfiles" \
        || test "$vfooter" -nt "$vdotfiles" \
        || test "$vconfig" -nt "$vdotfiles"; then
        echo "" > "$vdotfiles"
    fi
    vfulldirlist="$(get_dirs "$vcurrentfilelist" | grep -v "/res")"
    vfdiff=$(diff "$vdotfiles" <(echo "$vcurrentfilelist"))
    vfold=$(echo -e "$vfdiff" | grep -Po "^< \K.*$")
    vfnew="$(echo -e "$(echo -e "$vfdiff" | grep -Po "^> \K.*$")\n$(find_exclusion "$vroot/$vsrcname" -newer "$vdotfiles")" | grep . | sort -u)"
    # mandate the rebuild of the main index when there are changed files
    # this would stay here until I think of a better algorithm
    if ! (echo -e "$vfnew\n$vfold" | grep -q "$vroot/$vsrcname" | grep -vq "$vroot/$vsrcname$"); then
        vdirlist="$vroot/$vsrcname"
    fi
    vdirlist="$vdirlist $(get_dirs "$(cat <(echo -e "$vfnew") <(echo -e "$vfold"))" \
        | grep -v "/res")" || vdirlist="$vfulldirlist"
    # build html files for new or changed markdown files
    if [ "$vfnew" ]; then
        # we're going to build all file indices to make sure indice builds
        # have the correct info, but only build indices for dirs with changed files
        for dir1 in $vfulldirlist; do
            build_fileindex "$dir1" > "$dir1/.fileindex"
        done
        for dir2 in $vdirlist; do
            vcopylist="$vcopylist${dir2}/index.html\n"
            build_index "$dir2" > "$dir2/index.md"
            if $(mdtohtml "$dir2/index.md" > "$dir2/index.html"); then
                vresiduefilelist="$vresiduefilelist$dir2/index.html\n$dir2/index.md\n"
            else
                die "Failed to convert $dir2 index to HTML"
            fi
        done
        for mdfile in $(echo -e "$vfnew" | grep ".md$"); do
            htmlfilename="$(echo "$mdfile" | mdfilenametohtml)"
            if $(mdtohtml "$mdfile" > "$htmlfilename"); then
                vresiduefilelist="$vresiduefilelist$htmlfilename\n"
            else
                die "Failed to convert $mdfile to HTML"
            fi
            vcopylist="$vcopylist$htmlfilename\n"
        done
        vcopylist="$vcopylist$(echo -e "$vfnew" | grep -v ".md$")\n"
    fi
    # remove corresponding html files for removed markdown files
    if [ "$vfold" ]; then
        vremovelist="$vremovelist$(echo -e "$vfold" | srctodst | mdfilenametohtml)\n"
        echo -e "$vremovelist" | xargs -I {} rm {}
    fi
    if (test "$vcopylist"); then
        # remove blank lines
        vcopylist="$(echo -e "$vcopylist" | grep '.')"
        get_dirs "$vcopylist" | while read -r i; do
            mkdir -p "$(echo "$i" | srctodst)"
        done
        echo -e "$vcopylist" | sort -u | while read -r i; do
            cp "$i" "$(echo "$i" | srctodst)"
        done
        echo -e "$vcurrentfilelist" > "$vdotfiles"
        if test "$vresiduefilelist"; then
            echo -e "$vresiduefilelist" | xargs -I {} rm {} 2>/dev/null
        fi
        genrss
    else
        echo "No changes."
    fi
    # end profiler
    if (echo "$vargs" | grep -q 'p'); then
        set +x
        exec 2>&3 3>&-
    fi
}
die() {
    echo "$1" >&2 && exit 1
}
debug_echo() {
    echo "$vargs" | grep -q 'v' && echo -e "[debug] $1" >&2
}
script_init() {
    echo "No config file found. Creating one at $vconfig."
    cat >"$vconfig" <<EOF
# The name of your blog (website)
vblogname="$(whoami)"

# The topmost directory of your website. 
# Contains the source and destination directories.
vroot="$(pwd)"

# The name of your source directory
vsrcname="src"

# The name of your destination directory
vdstname="pages"

# The name of your header file. Header files are included at the top of all pages.
vheadername="header"

# The name of your footer file. Footer files are included at the bottom of all pages.
vfootername="footer"

# The markdown converter command you would be using. For pandoc,
# the command would be "pandoc -f markdown -t html".
vmdconvcommand="pandoc -f markdown -t html"

### RSS config ###

# The URL of your site
vrssurl="https://ltlnx.tw"

# The title of your site
vrsstitle="Blog of ltlnx - All pages"

# The description of the site
vrssdesc="All pages on the website of ltlnx"

# The language of the site (defined by your language code, e.g. "en" for English,
# with an optional region code, e.g. "zh-tw" for Chinese in Taiwan)
vrsslang="zh-tw"

# The copyright of your RSS file content
vrsscopyright="Wen-Wei Kao"

# The URL of the RSS feed
vrssfeedurl="https://ltlnx.tw/rssfeed.xml"
EOF
    echo "Please adjust the config file to your needs before running the script again."
    exit 0
}
run_tests() {
    test "$vblogname" || echo "vblogname not set."
    test -d "$vroot" || echo "The topmost directory $vroot does not exist."
    test -d "$vroot"/"$vsrcname" || echo "The source directory $vroot/$vsrcname does not exist."
    test -d "$vroot"/"$vdstname" || echo "The destination directory $vroot/$vdstname does not exist."
    test "$vheadername" || echo "vheadername not set."
    test -f "$vroot"/"$vheadername" || echo "Header file not found. Please put a header file under the topmost directory."
    test "$vfootername" || echo "vfootername not set."
    test -f "$vroot"/"$vfootername" || echo "Footer file not found. Please put a footer file under the topmost directory."
    which $(echo "$vmdconvcommand" | cut -d ' ' -f 1) >/dev/null || echo "No supported Markdown parser found. Please set it up in the config file."
}
argsparse() {
    local args=$(echo "$1" | grep -o "[[:alnum:]]" | sort -u) \
        || die "Failed to parse arguments"
    echo "$args" | grep -q "h" && print_help && exit 0
    echo "$args" && return 0 || return 1
}
# for the two find functions we use $@ instead of $1 to preserve arguments
# passed to the function
find_exclusion() {
    find "$@" -type f \
        -not -path "*/beta/*" -not -path "*/beta" \
        -not -path "*/notes/*" -not -path "*/notes" \
        -not -path "*/.*" -not -name "desc" \
        -not -name "index.md" -not -name "$vheadername" -not -name "$vfootername"
}
find_dirs_exclusion() {
    find "$@" -type d -mindepth 1 -not -path "*/res/*" -not -path "*/res" -not -path "*/.*"
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
    echo -e "$(echo "$inp" | sed 's/.md$/.html/g')"
}
build_fileindex() {
    cd "$1"
    debug_echo "Building fileindex for $1"
    local fileindex=""
    for mdfile in \
        $(find "$1" -mindepth 1 -maxdepth 1 -path "*.md" -not -name "index.md" -not -path "*/.*"); do
        local D=$(cat "$mdfile" | grep -Po '^[\_]*Last [[:alpha:]]*: \K[^\_]*' \
            || echo "(No date)")
        local T=$(head -n 5 "$mdfile" | grep -Po "^# \K.*$" | rmhtmltags)
        local P=$(basename "$mdfile" | mdfilenametohtml | sed "s|^\./||g")
        fileindex="$fileindex- <span class=\"date\">$D</span>[$T]($P)\n"
    done
    test "$fileindex" && echo -e "$fileindex" | sort -r -n
}
build_index() {
    cd "$1"
    debug_echo "Building index for $1"
    local index="$(cat desc 2>/dev/null)" \
        || index="# $(basename "$1" | titlize)\n\nNo description.\n\n---\n"
    for subdir in $(find_dirs_exclusion "$1" | sort); do
        debug_echo "Creating sub-index for $subdir"
        test -f "$subdir/.fileindex" || continue
        index="$index\n\n### $(basename "$subdir" | titlize)\n"
        index="$index$(head -n 10 "$subdir/.fileindex" | \
            sed "s|](|]($(basename "$subdir")/|g")"
        index="$index$(if [ $(wc -l < "$subdir/.fileindex") -gt 11 ]; then
            echo "\n\n[More →]"
        else
            echo "\n\n[Dedicated page →]"
        fi)($(basename "$subdir")/index.html)"
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
        echo $(echo -e "$(for i in $(echo "$1" | rev | cut -d '/' -f 2- | rev | sed "s|$vroot/$vsrcname||" | grep -o "\b[^/]*" | tac); do echo "[$(echo "$i" | titlize)]($dotdot) >"; dotdot="../$dotdot"; done; echo "[$vblogname]($dotdot) >")" | tac) | $vmdconvcommand
    elif [ "$1" != "$vroot/$vsrcname/index.md" ]; then
        dotdot="../index.html"
        echo $(echo -e "$(for i in $(echo "$1" | rev | cut -d '/' -f 3- | rev | sed "s|$vroot/$vsrcname||" | grep -o "\b[^/]*" | tac); do echo "[$(echo "$i" | titlize)]($dotdot) >"; dotdot="../$dotdot"; done; echo "[$vblogname]($dotdot) >")" | tac; echo "**$(echo "$1" | rev | cut -d '/' -f 2 | rev | titlize)**") | $vmdconvcommand
    else
        echo "<p><strong>$vblogname</strong></p>"
    fi
}
parse_shortcodes() {
    parsed_content="$1"
    for i in $(echo -e "$parsed_content" | grep -Po "{{\K.*?(?=}})"); do
        parsed_content=$(echo -e "$parsed_content" | sed "s|{{$i}}|$(cat "$vroot"/shortcodes/"$i")|")
    done
    echo -e "$parsed_content"
}
mdtohtml() {
    local content=""
    page_title="$(head -n 5 "$1" | grep -Po "^# \K.*$" | rmhtmltags) - Blog of ltlnx" || return 1
    content="$content$(cat "$vheader" | sed "s|<title>|<title>$page_title|g; s|<p id=\"nav\"></p>|$(echo $(gennav "$1" | sed 's/<p>/<p id="nav">/;s/\&/\\\&/g'))|g")\n" || return 1
    content="$content$($vmdconvcommand < "$1")\n" || return 1
    content="$content$(cat "$vfooter")\n" || return 1
    echo -e "$(parse_shortcodes "$content")" || return 1
}
genrss() {
    # rss item generation
    mv "$vroot/rssitems" "$vroot/rssitems.old"
    for mdfile in $(echo -e "$vcurrentfilelist" | grep ".md$"); do
        # get info of markdown file
        it_title="$(head -n 5 "$mdfile" | grep -Po "^# \K.*$" | rmhtmltags)"
        it_guid="$(echo "$mdfile" | grep -Po "^$vroot/$vsrcname/\K.*$" | mdfilenametohtml)"
        it_link="https://ltlnx.tw/$it_guid"
        it_pubDate="$(date -d "$(cat "$mdfile" | grep -Po '^[\_]*Last [[:alpha:]]*: \K[^\_]*' || echo "1970-01-01")" -R)"
        it_description="$(cat "$mdfile" | grep -v "^> " | grep -v "^# " | pandoc -f markdown -t plain | sed -n "/^/,/^$/p; /^$/q")"
        cat >> "$vroot/rssitems" <<EOF 
<item>
 <title>$it_title</title>
 <link>$it_link</link>
 <guid isPermaLink="false">$it_guid</guid>
 <pubDate>$it_pubDate</pubDate>
 <description><![CDATA[$it_description]]></description>
</item>
EOF
    done
    builddate=$(date -R)
    # initial overhead
    cat > "$vroot/$vdstname/rssfeed.xml" <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>$vrsstitle</title>
    <link>$vrssurl</link>
    <description>$vrssdesc</description>
    <language>$vrsslang</language>
    <copyright>$vrsscopyright</copyright>
    <lastBuildDate>$builddate</lastBuildDate>
    <atom:link href="$vrssfeedurl" rel="self" type="application/rss+xml" />
EOF
    # items
    cat "$vroot/rssitems" >> "$vroot/$vdstname/rssfeed.xml" 
    # ending
    cat >> "$vroot/$vdstname/rssfeed.xml" <<EOF
  </channel>
</rss>
EOF
}

main "$@"
