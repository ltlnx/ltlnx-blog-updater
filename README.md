# ltlnx's blog updater
This is ltlnx's blog updater: it takes a source directory with Markdown files, a "header" and a "footer", converts them to HTML, and copies them to the desired destination directory.

### Prerequisites
- any bourne-compatible shell (tested with ksh, bash, ash, dash, and sh)
- GNU grep (or a grep supporting `-P`)
- GNU sed
- Pandoc for Markdown conversion, or you can edit the `vmdconvcommand` to supplant with your own Markdown convertor.

There may be something missing here but in general, a Linux system with pandoc installed would probably work. (If not, please create an issue.)

### Setup (on Linux)
1. Open a terminal and clone this repo.
2. Go into the cloned directory: `cd ltlnx-blog-updater`
3. Make sure the script is executable: `chmod u+x update.sh`
4. Initialization: `./update.sh init`. At this point a minimal blog example would be created.
5. Edit details in the `.updaterc` file as necessary.
6. Run the script again.
7. Copy the generated files to your web server directory, or if you have python3 installed, run `./update.sh serve` and go to [0.0.0.0:8000](http://0.0.0.0:8000) with your preferred web browser.

### Writing blog posts and tag descriptions
Both blog posts and tag descriptions should be Markdown files in the source directory (`src` by default). Blog posts have the suffix `.md`, and descriptions have the suffix `.desc`. Say if you want to add a new tag named "tech":

- Write a blog post and add `Tags: tech` at the end of the file (or anywhere beneath the title).
- In the source directory, add a file named `tech.desc`.
- Add to the file a description that looks like the following:
  ```
  # Tech-related stuff

  Here are all my tech-related stuff.
  ```
- Rebuild the blog by running `update.sh`.

After running, you should ba able to go to `dst/tags/tech.html` to make sure that it's applied, and has a link to the blog post.

### Dates
To specify the date of a post, you can do one of the following:

- Add a date on its own line, e.g. `2023-11-03`
- Add a date after "Last updated: ", e.g. `Last updated: 2023-11-03`

Both would work equally fine. Just make sure that you don't specify two dates for the same post, or the updater script would pick the first one.

By default, the updater would put posts with dates under their respective year (a post named `hello.md` with the date `2023-11-03` would be converted to `2023/hello.html`), and posts without dates directly in the destination directory (`dst` by default).

### "Themeing"
To "theme" your site, add a CSS file, preferably named `style.css`, in the source directory. A minimal example is included after you run `./update.sh init`. You can inspect the generated HTML (with Firefox's inspector, a text editor or whatever) and determine which target to write styles for.

### RSS (Atom) and a sitemap
This script also generates an RSS feed named "atom.xml" in the destination directory. You can decide what to do with it. When deploying with the script, a "sitemap.xml" will be generated, or you can generate it manually by running `./update.sh gensitemap`.

### Contributing / Bug reports
This script currently doesn't accept pull requests, but you're welcome to report bugs in Github Issues or directly to ltlnx dot tw at gmail dot com. Thanks for discovering and using my script!
