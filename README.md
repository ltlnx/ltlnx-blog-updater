# ltlnx's blog updater
This is my blog updater: it takes a source directory with Markdown files, a "header" and a "footer", converts them to HTML, and copies them to the desired destination directory.

### Prerequisites
The script currently assumes a UNIX-like environment with GNU `grep` and `sed`. I may turn some expressions into perl expressions for better compatibility. Also, `pandoc` should be in your path; please see [pandoc.org](https://pandoc.org) for install instructions.

You should set up two directories in the same directory as the script: `src` and `pages`. Also in the same directory, add a `style.css` file if you want to apply styles to pages. In the `src` directory, there should be two files: `header` and `footer`, which corresponds to the top and bottom of all HTML files.

In the `src` directory, you may add directories which would become categories after you run the script. In every directory there may be a `desc` file, which would contain the description of the category in Markdown.

This repo contains a minimal example for all of the above. After cloning, first modify two places: the value of `vroot` in `update.sh`, and the `href` value in `style.css` to reflect the actual location of the files, then run `update.sh` directly and see what appears in the `pages` directory. After that, you can modify the script and files to fit your needs.

### Contributing / Bug reports
This script currently doesn't accept pull requests, but you're welcome to report bugs in Github Issues or directly to ltlnx dot tw at gmail dot com. Thanks for discovering and using my script!
