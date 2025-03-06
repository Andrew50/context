# Simple Format Script

## Overview
`simple_format.bash` is a utility script that helps you generate context files for LLM prompts by collecting content from multiple files.

## How to Use

1. Run the script:
   ```bash
   ./simple_format.bash
   ```

2. The script will open a text editor (nvim) with a file called `scripts.txt`.

3. In `scripts.txt`, add the paths of files you want to include in your context, one file per line.
   For example:
   ```
   src/main.js
   config.json
   lib/utils.js
   ```

4. Save and exit the editor (`:wq` in nvim).

5. The script will search for these files in various locations:
   - Current directory
   - Parent directories
   - Specific paths like `/home/aj/dev/study/`

6. A file called `llm_context.txt` will be generated containing the content of all found files.

## Notes
- Files that can't be found will be reported in the terminal
- The script uses both exact path matching and fuzzy search to find your files
- The generated context file is formatted with Markdown headers and code blocks