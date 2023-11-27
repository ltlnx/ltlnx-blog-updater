#!/bin/bash
# ltlnx's blog updater script, rewritten 20231103

# TODO
# - readme
# - some sort of help on the command line
# - augument sample description and markdown files

# messages and errors
msg() {
    printf "[MSG] $@\n"
}
die() {
    printf "[ERR] $@\n" && exit 1
}

# config and minimal blog boilerplate
create_config() {
    test "$1" || return 1
    cat > "$1" <<EOF
### Location config ###

# The title of your site
vtitle="Blog of $(whoami)"

# The topmost directory of your website.
# Contains the source and destination directories, and the update script.
vroot="$(dirname "$0")"

# The name of your source directory
vsrcname="src"

# The name of your destination directory
vdstname="dst"

# The name of your header file. Header files are included at the top of all pages.
# Write the header in html and end with a opening tag like <main>.
vheadername="header"

# The name of your footer file. Footer files are included at the bottom of all pages.
# Write the footer in html starting with a closing tag like </main>.
vfootername="footer"

# The markdown converter command you would be using. For pandoc,
# the command would be "pandoc -f markdown -t html".
vmdconvcommand="pandoc -f markdown -t html"

# The URL of your site, used for generating sitemaps and RSS feeds
vurl="https://example.org"

### RSS (Atom) config ###

# The description of the site
vdesc="All pages on the blog of $(whoami)"

# The language of the site (defined by your language code, e.g. "en" for English,
# with an optional region code, e.g. "zh-TW" for Chinese in Taiwan)
vlang="en"

# The name of the main author (an alias would suffice)
vname="$(whoami)"

# The copyright of your RSS file content
vcopyright="ⓒ $(whoami) $(date +%Y)."

# The filename of your feed file. You may leave this intact unless you had a
# blog with a canonical feed URL established already.
vfeedname="atom.xml"

# The URL of the RSS feed.
# It should look somewhat like "https://<yoursite.com>/atom.xml".
vfeedurl="https://example.org/atom.xml"
EOF
}

create_header() {
    test "$1" || return 1
    cat > "$1" <<EOF
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <!-- The script would insert a title here -->
        <title></title>
        <meta name="viewport" content="width=device-width">
        <link rel="stylesheet" type="text/css" href="/style.css">
        <link rel="icon" href="data:,">
        <link rel="alternate" type="application/atom+xml" title="RSS (Atom) of all pages" href="/atom.xml">
    </head>
    <body>
        <div id="header">
            <a href="/index.html" id="sitename"><strong>Insert Blog Name Here</strong></a>
            <div class='links'>
                <a href='/archive.html'>Archive</a>
                <a href='/tags/index.html'>Tags</a>
                <a href='/about.html'>About</a>
                <a href='/atom.xml'>RSS</a>
            </div>
        </div>
        <div id="main">
EOF
}

create_footer() {
    test "$1" || return 1
    cat > "$1" <<EOF
        </div>
        <div id="footer">
            <div class='links'>
                <a href='/archive.html'>Archive</a>
                <a href='/tags/index.html'>Tags</a>
                <a href='/about.html'>About</a>
                <a href='/atom.xml'>RSS</a>
            </div>
            <small>ⓒ $(whoami) $(date +%Y).</small>
        </div>
    </body>
</html>
EOF
}

create_stylesheet() {
    test "$1" || return 1
    cat > "$1" <<EOF
html {
    margin: auto;
    max-width: 52rem;
    background: #f1f1f1;
    color: #54433a;
    font-family: "Noto Serif", -apple-system-ui-serif, ui-serif, Georgia, serif;
}
body {overflow-x: hidden}
pre, blockquote {overflow-x: auto; background: #e9e6e4; padding: 1em}
blockquote {margin: 0; border-left: 0.75em solid}
blockquote > * {margin: 0 0 0.25em 0.25em}
ul, ol {padding-left: 1em}
a {color: #465aa4}
#header a, .links a {text-decoration: none}
#sitename, .links a:hover {color: #7d6658}
#header a, .links a, .tags a {padding: 0 0.1em 0 0}
hr {border: 0.75px solid}
EOF
}

create_desc() {
    test "$1" || return 1
    test "$2" || return 1
    cat > "$1" <<EOF
# "$2" Example Description File

This page is the $2 page. The content of this block comes from a \`.desc\` file of the same name in the source directory that you can modify.

EOF
}

create_examplemd() {
    test "$1" || return 1
    test "$2" || return 1
    cat > "$1" <<EOF
# $2 post

This post is an $2 post. If the post is in the "sticky" folder, it won't show in the archives, but otherwise you can put your Markdown files anywhere in the source directory.

Add tags at the end of the post starting with \`Tags: \` and a list of comma-separated tags.

For dates, add one line that has a date on its own, in the YYYY-MM-DD format.

Tags: example,example2

$(date +%Y-%m-%d)
EOF
}

# config stuff and initialization
vconfig="$(dirname "$0")/.updaterc"

if [ "$1" = "init" ]; then
    if [ -f "$vconfig" ]; then
        msg "Config file exists. Creating a config to $vconfig.new."
        create_config "$vconfig.new"
    else
        msg "Creating a config to $vconfig."
        create_config "$vconfig"
    fi
    source "$vconfig" || die "Something went wrong while sourcing $vconfig."
    test -d "$vroot/$vsrcname" || mkdir -p "$vroot/$vsrcname"
    test -d "$vroot/$vdstname" || mkdir -p "$vroot/$vdstname"
    test -d "$vroot/$vsrcname/sticky" || mkdir -p "$vroot/$vsrcname/sticky"
    test -f "$vroot/$vheadername" || create_header "$vroot/$vheadername" \
        && msg "Created header file at $vroot/$vheadername."
    test -f "$vroot/$vfootername" || create_footer "$vroot/$vfootername" \
        && msg "Created footer file at $vroot/$vfootername."
    test -f "$vroot/$vsrcname/style.css" || create_stylesheet "$vroot/$vsrcname/style.css" && msg "Created stylesheet at $vroot/$vsrcname/style.css."
    for file in "archive" "tags" "example" "example2"; do
        test -f "$vroot/$vsrcname/$file.desc" || create_desc "$vroot/$vsrcname/$file.desc" "$file" && msg "Created folder description at $vroot/$vsrcname/$file.desc."
    done
    test -f "$vroot/$vsrcname/example.md" || create_examplemd "$vroot/$vsrcname/example.md" "example" && msg "Created example Markdown post file at $vroot/$vsrcname/example.md."
    for file in "about" "index"; do
        test -f "$vroot/$vsrcname/sticky/$file.md" \
            || create_examplemd "$vroot/$vsrcname/sticky/$file.md" "$file" \
            && msg "Created example sticky Markdown file at $vroot/$vsrcname/sticky/$file.md."
    done
    msg "You're good to go!"
    msg "Please edit the details of $vconfig and run $0 again."
    exit 0
fi

if [ ! -f "$vconfig" ]; then 
    msg "No config file found. Please put a config file named .updaterc"
    msg "under the same folder as this script, or run"
    msg "\`$0 init\` to initialize."
    exit 1
fi
source "$vconfig"

# test if things are there and if not, bail out
E=0
if [ ! -d "$vroot/$vsrcname" ]; then
    msg "Source folder $vroot/$vsrcname not found." && E=1
fi
if [ ! -d "$vroot/$vdstname" ]; then
    msg "Destination folder $vroot/$vdstname not found." && E=1
fi
if [ ! -f "$vroot/$vheadername" ]; then
    msg "Header file $vroot/$vheadername not found." && E=1
fi
if [ ! -f "$vroot/$vfootername" ]; then
    msg "Footer file $vroot/$vfootername not found." && E=1
fi
if [ -z "$vmdconvcommand" ]; then
    msg "Markdown conversion command not set; defaulting to pandoc."
    vmdconvcommand="pandoc -f markdown -t html"
fi
if [ -z "$vname" ]; then
    msg "Name not set; defaulting to the blog title."
    msg "(Sadly Atom feeds require an author to be valid)"
    vname="$vtitle"
fi
if [ "$E" -ne 0 ]; then
    die "Please fix them in the config $vconfig, or run \`$0 init\` to\ncreate a new set of files."
fi

# sitemap generation
gensitemap() {
    cd "$vroot/$vdstname" || die "Either you haven't created the destination folder, or the config has wrong settings. Please check if everything is set up."
    # initial overhead
    cat > "sitemap.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOF
    # items
    for item in $(find . -name "*.html" -printf "%P\n"); do
        # get info of markdown file
        it_loc="${vurl}/$item"
        it_lastmod="$(date -d "$(cat "$item" | grep -Po '^<p>.*[\_]*Last [[:alpha:]]*: \K[^\<]*' || cat "$item" | grep -o "^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$" || date +"%Y-%m-%d")" -R)"
        cat >> "sitemap.xml" <<EOF
<url>
 <loc>$it_loc</loc>
 <lastmod>$it_lastmod</lastmod>
</url>
EOF
    done
    # ending
    cat >> "sitemap.xml" <<EOF
</urlset>
EOF
    cd -
}

# quick actions
case "$1" in
    deploy)
        test "$2" || die "Please input a commit message"
        test "$3" && die "Please put the commit message in quotes"
        gensitemap
        cd "$vroot"/"$vdstname" || die "Either you haven't created the destination folder, or the config has wrong settings. Please check if everything is set up."
        git add . || die "The destination directory is not versioned by git."
        git commit -m "$2"
        git push
        cd -
        exit 0
        ;;
    gensitemap)
        gensitemap
        exit 0
        ;;
    serve)
        cd "$vroot"/"$vdstname" || exit 1
        python3 -m http.server || die "Your system probably does not have Python 3 installed. Please change the line invoking python3 into your own web server command, or install Python 3."
        cd -
        exit 0
        ;;
esac

# copy the whole source dir to destination
rm -r $vroot/$vdstname/*
cp -r $vroot/$vsrcname/* "$vroot/$vdstname"

# kickstart the RSS feed
cat > "$vroot/$vdstname/$vfeedname" <<EOF
<?xml version="1.0" encoding="utf-8" ?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="$vlang">
  <title>$vtitle</title>
  <id>$vurl/</id>
  <updated>$(date +%Y-%m-%dT%T%:z)</updated>
  <author>
    <name>$vname</name>
  </author>
  <subtitle>$vdesc</subtitle>
  <rights>$vcopyright</rights>
  <link href="$vfeedurl" rel="self"/>
EOF

# RSS feed cumulative item generating function
genrss() {
    if [ -n "$date" ]; then
        pubDate="$(date -d "$date" +%Y-%m-%dT%T%:z)"
    else
        pubDate="2020-01-01T00:00:00+08:00"
    fi
    postcontent="$(head -n 30 "$file" | grep -v "> " | sed "s|<[^>]*>||g" | sed -n '/^# /,/^.*/d; 1,/^$/p' | grep . )"
    cat >> "$vroot/$vdstname/$vfeedname" <<EOF
  <entry>
    <title>$title</title>
    <link rel="alternate" href="$vurl$link"/>
    <id>$vurl$link/</id>
    <author>
      <name>$vname</name>
    </author>
    <updated>$pubDate</updated>
    <summary>$postcontent</summary>
  </entry>
EOF
}
# post conversion
# the code is dense, yeah, I'm sorry.
mkdir -p "$vroot/$vdstname/tags"
find "$vroot/$vsrcname" -path "*.md" | while read -r file; do
    msg "Processing $file"
    filebn="$(basename "$file" .md)"
    # the title should be on the first three lines (preferably the first)
    # and starts with a markdown # (single hash sign)
    title="$(head -n 3 "$file" | grep -Po "^# \K.*$" | sed "s|<[^>]*>||g")"
    # for the date we support 2 schemes:
    # one is the date itself on one line, another is "Last <any word>: <date>",
    # with or without italic `_` marks around them.
    date="$(cat "$file" | grep -o "^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$")" \
        || date="$(cat "$file" | grep -Po '^[_]*Last [^:]*: \K[^\_]*')"
    # there may be unfortunate cases where multiple dates are found,
    # for which we pick the first one
    date="$(echo "$date" | head -n 1)"
    # year for categorizing
    year="$(echo "$date" | grep -o "[0-9]\{4\}")"
    # tags start with "Tags: " of "tags: ", and is comma-separated
    tags="$(cat "$file" | grep -Po "^[Tt]ags: \K.*" | grep -Po '(?!( ))[^,]*' | sed 's| |-|g')" 
    test "$tags" && htmltaglist="<span class=\"tags\">Tags: $(printf "$tags\n" | while read -r line; do printf "<a href=\"/tags/$line.html\">$line</a> "; done)</span>"
    # just define the link as the filename, no more categorizing by year
    link="/$filebn.html"
    # duplicate filename solving
    if [ -f "$vroot/${vdstname}${link}" ]; then
        link="$(echo "$link" | sed "s|.html|-$(find "$vroot/$vdstname" -name "$filebn-[0-9]*.html" | wc -l).html|")"
    fi
    # all titles are generated as
    # <the h1 title> - <blog name>
    cat > "$vroot/${vdstname}${link}" <<EOF
$(cat "$vroot/$vheadername" | sed "s|<title>|<title>$title - $vtitle|")
$(cat "$file" | sed "s|^[Tt]ags: .*$|$htmltaglist|g" | $vmdconvcommand)
$(cat "$vroot/$vfootername")
EOF
    entry="- <span class=\"date\">$date</span> [$title]($link)"
    # throw the entry into the appropriate catalogs
    # throw it into the archive if it's not a sticky post
    if ! (echo "$file" | grep -q "$vsrcname/sticky"); then
        echo "$entry" >> "$vroot/$vdstname/archive.md"
    fi
    if [ -n "$tags" ]; then
        printf "$tags\n" | while read -r tag; do
            echo "$entry" >> "$vroot/$vdstname/tags/$tag.md"
        done
    fi
    # generate rss entry
    genrss
done

# make tag indexes into proper pages
find "$vroot/$vdstname/tags" -path "*.md" | while read -r file; do
    filebn="$(basename "$file" .md)"
    title="$(echo "$filebn" | sed 's|-| |g;s|\b\(.\)|\u\1|g')"
    link="/tags/$filebn.html"
    desc="$(cat "$vroot/$vsrcname/$filebn.desc")" || desc="No description.\n"
    content="$(cat "$file" | sort -rn)"
    cat > "$vroot/${vdstname}${link}" <<EOF
$(cat "$vroot/$vheadername" | sed "s|<title>|<title>$title - $vtitle|")
$(printf "$desc\n\n$content\n" | $vmdconvcommand)
$(cat "$vroot/$vfootername")
EOF
    echo " [$title]($link)" >> "$vroot/$vdstname/tags/index.md"
done

# make tag page
desc="$(cat "$vroot/$vsrcname/tags.desc")" || desc="No description.\n"
tagscontent="$(cat "$vroot/$vdstname/tags/index.md")"
cat > "$vroot/$vdstname/tags/index.html" <<EOF
$(cat "$vroot/$vheadername" | sed "s|<title>|<title>Tags - $vtitle|")
$(printf "$desc\n\n\n$(printf "$tagscontent" | sed 's/^/-/g')\n" | $vmdconvcommand)
$(cat "$vroot/$vfootername")
EOF

# make archive page
desc="$(cat "$vroot/$vsrcname/archive.desc")" || desc="No description.\n"
content="$(cat "$vroot/$vdstname/archive.md" | sort -rn)"
cat > "$vroot/$vdstname/archive.html" <<EOF
$(cat "$vroot/$vheadername" | sed "s|<title>|<title>Archive - $vtitle|")
$(printf "$desc\n\nTags:$tagscontent\n\n$content\n" | $vmdconvcommand)
$(cat "$vroot/$vfootername")
EOF

# close RSS generation
echo "</feed>" >> "$vroot/$vdstname/$vfeedname"

# remove leftover files and empty directories in the destination
find "$vroot/$vdstname" -path "*.md" | xargs rm || true
find "$vroot/$vdstname" -path "*.desc" | xargs rm || true
find "$vroot/$vdstname" -mindepth 1 -type d -empty -delete || true
