# ltlnx's blog updater
This is my blog updater: it takes a source directory with Markdown files, a "header" and a "footer", converts them to HTML, and copies them to the desired destination directory.

### Prerequisites
- a shell with `echo -e` support (i.e. most Linux distros with GNU or Busybox utils)
- GNU grep (or a grep supporting `-P`)
- GNU sed
- Pandoc

There may be something missing here but in general, a Linux system with pandoc installed would probably work. (If not, create an issue.)

### Setup (on Linux)
1. Open a terminal and clone this repo.
2. Go into the cloned directory: `cd ltlnx-blog-updater`
3. Make sure the script is executable: `chmod u+x update.sh`
4. Run it : `./update.sh`

At this point the script would create a file named `updater_config` in the directory. Please change the details to your liking.

### Writing blog posts and updating files
Change into the source directory `src`.

- To form a "category", create a new directory with the category name. The first letter will be capitalized and hyphens will be turned into spaces. e.g. `public-logs` becomes `Public Logs`.
- To add a date to links on the index pages, add a line with `Last updated: <date>`. You can replace `updated: ` with another word or add underscores (`_`) around them and it'll still work. See the demo posts in the `src` directory for more info.
- To "theme" your site, add a CSS file, preferably named `style.css`, in the source directory. A minimal example is included. You can inspect the generated HTML (with Firefox's inspector, a text editor or whatever) and determine which target to write styles for.
- To add a description on the top of index pages, add a file named "desc" in the directories you want a description, and add Markdown content to the file. Again, see the `desc` files in the source directory for an example.

### RSS
This script also generates an RSS feed named "rssfeed.xml" in the destination directory. You can decide what to do with it (add a link to it maybe?)

### Contributing / Bug reports
This script currently doesn't accept pull requests, but you're welcome to report bugs in Github Issues or directly to ltlnx dot tw at gmail dot com. Thanks for discovering and using my script!
