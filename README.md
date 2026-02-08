# Directory Structure Creator

This script (`create_dirs.sh`) reads a folder structure from a file and creates directories accordingly.

## Usage

1. Place your folder structure in a file named `folder-structure.txt` (default) or specify a custom file name. Each line should contain a folder name. Indent child folders with two spaces for each level:

```
home
  user
    desktop
    document
    download
```

2. Run the script with the default file:

```sh
./create_dirs.sh
```

Or specify a custom folder list file:

```sh
./create_dirs.sh myfolders.txt
```

This will create the directories in your current working directory. If a folder already exists, it will be skipped and not recreated.

**Output details:**
- In normal mode, the script prints `CREATED:` for each folder that is actually created, and `SKIPPED:` for each folder that already exists.
- In dry run mode, the script prints `CREATE:` for folders that would be created, and `SKIP:` for folders that would be skipped.

### Remove Base Path from Output
To display only relative folder paths (without the base path) in terminal output and logs, use the `--no-base-path` option:

```sh
./create_dirs.sh --no-base-path
```

This will strip the current working directory from all output and log entries, showing only the relative folder structure.


**Note:**
- If the specified folder list file (or the default `folder-structure.txt`) does not exist, the script will stop and output an error message.
- The script is POSIX-compliant and has robust argument parsing and error handling for safe usage.

### Dry Run
To preview the directories that will be created, use the `--dry-run` option:

```sh
./create_dirs.sh --dry-run
```

Or combine with a custom file:

```sh
./create_dirs.sh myfolders.txt --dry-run
```


### Logging
You can log all actions (with timestamps) to a file using the `--log` switch:

```sh
./create_dirs.sh --log [filename]
```

If you specify a custom log filename, the script will automatically append `.log` to the filename if it does not already end with `.log`. For example, `--log myfile` will create/use `myfile.log`, and `--log myfile.txt` will create/use `myfile.log`. If you use `--log` without specifying a filename, the default log file `logger.log` will be used.

If you use `--log` without specifying a filename, the default log file `logger.log` will be used.

Log entries are always appended (never overwritten). Each run starts with a timestamped header indicating whether it was a dry run or an actual run.

### Help
To display usage instructions and available switches, use the `--help` option:

```sh
./create_dirs.sh --help
```

This will show usage, options, and a short explanation of the script's functionality.

## Requirements
- POSIX-compliant shell (e.g., sh, bash)
- `folder-structure.txt` (default) or a custom file in the same directory as the script

## Notes
- Each two spaces at the start of a line indicate a child folder level.
- Indentation rules:
  - A child folder must not be more than 2 spaces further indented than the previous non-empty line (parent).
  - All child indentation must be in 2 spaces (not 1, 3, 5, etc.).
  - If any line violates these rules, the script will output an error and stop execution.
- Example of valid indentation:
  ```
  home
    user
      desktop
      documents
  ```
- Example of invalid indentation (will cause an error):
  ```
  home
     user  # 5 spaces (not allowed)
  ```
- The script must be run from the directory where you want the folders created.
