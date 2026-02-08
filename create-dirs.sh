#!/bin/sh

base_path="$(pwd)"
dry_run=0
custom_file=""

# Help text
print_help() {
	echo "Usage: $0 [folder-list-file] [--dry-run] [--help] [--log <file>]"
	echo
	echo "Options:"
	echo "  folder-list-file   Optional. Custom file listing folders (default: folder-structure.txt)"
	echo "  --dry-run          Print the folder paths that would be created, but do not create them"
	echo "  --help             Show this help message and exit"
	echo "  --log <file>       Log actions with timestamps to the specified file"
	echo "  --no-base-path     Remove the base path from terminal output paths"
	echo
	echo "Functionality:"
	echo "  This script reads a folder structure from a file, where each line is a folder name."
	echo "  Indent child folders with two spaces per level. The script creates the directory structure"
	echo "  in the current working directory."
}

# Parse arguments

log_file=""
log_flag=0
prev_arg=""
no_base_path=0
for arg in "$@"; do
	if [ "$arg" = "--dry-run" ]; then
		dry_run=1
	elif [ "$arg" = "--help" ]; then
		print_help
		exit 0
	elif [ "$arg" = "--no-base-path" ]; then
		no_base_path=1
	elif [ "$arg" = "--log" ]; then
		log_flag=1
		prev_arg="--log"
		continue
	elif [ "$prev_arg" = "--log" ]; then
		log_file="$arg"
		log_flag=0
		prev_arg=""
		continue
	elif [ -z "$custom_file" ] && [ "$arg" != "--dry-run" ]; then
		custom_file="$arg"
	fi
	prev_arg=""
done

# If --log was provided but no filename, use logger.log
if [ "$log_flag" -eq 1 ]; then
	log_file="logger.log"
fi

# Ensure log_file ends with .log if set
if [ -n "$log_file" ]; then
	case "$log_file" in
		*.log) : ;;
		*) log_file="$log_file.log" ;;
	 esac
fi


# Set input file
if [ -n "$custom_file" ]; then
	input_file="$base_path/$custom_file"
else
	input_file="$base_path/folder-structure.txt"
fi

# Check if input file exists
if [ ! -f "$input_file" ]; then
	echo "Error: Folder list file '$input_file' not found." >&2
	exit 1
fi


# Track parent folders by depth using positional parameters
set --

# Check indentation rule before processing
prev_spaces=0
line_num=0
error_found=0
while IFS= read -r check_line; do
	line_num=$((line_num + 1))
	# Skip empty lines
	[ -z "$(echo "$check_line" | sed 's/^ *//')" ] && continue
	# Count leading spaces
	check_spaces=$(echo "$check_line" | sed -n 's/^\( *\).*$/\1/p' | wc -c)
	check_spaces=$((check_spaces - 1))
	RED_BOLD="\033[1;31m"
	NC="\033[0m"
	# If not the first non-empty line, check indentation
	if [ $line_num -gt 1 ]; then
		diff=$((check_spaces - prev_spaces))
		if [ $diff -gt 2 ]; then
			printf "${RED_BOLD}ERROR:${NC} Improper indentation on line %d: '%s' (indented %d spaces, previous %d). Child must not be more than +2 spaces indented from previous parent.\n" "$line_num" "$(echo "$check_line" | sed 's/^ *//')" "$check_spaces" "$prev_spaces" >&2
			error_found=1
		elif [ $check_spaces -gt 0 ] && [ $((check_spaces % 2)) -ne 0 ]; then
			printf "${RED_BOLD}ERROR:${NC} Indentation on line %d: '%s' is %d spaces, which is not divisible by 2. Make sure space indentation is based on 2.\n" "$line_num" "$(echo "$check_line" | sed 's/^ *//')" "$check_spaces" >&2
			error_found=1
		fi
	fi
	prev_spaces=$check_spaces
done < "$input_file"
if [ $error_found -eq 1 ]; then
	exit 1
fi


if [ -n "$log_file" ]; then
	log_start_time=$(date '+%Y-%m-%d %H:%M:%S')
	if [ "$dry_run" -eq 1 ]; then
		echo "$log_start_time [LOG START] DRY RUN mode enabled" >> "$log_file"
	else
		echo "$log_start_time [LOG START] ACTUAL RUN (folders will be created/skipped)" >> "$log_file"
	fi
fi

parent_stack=""
while IFS= read -r line; do
	timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	# Count leading spaces
	spaces=$(echo "$line" | sed -n 's/^\( *\).*$/\1/p' | wc -c)
	spaces=$((spaces - 1)) # wc -c counts the newline

	# Remove leading spaces to get folder name
	folder=$(echo "$line" | sed 's/^ *//')

	# Skip empty lines
	[ -z "$folder" ] && continue

	# Calculate depth (2 spaces per level)
	depth=$((spaces / 2))

	# Maintain parent stack as a space-separated string
	# Use an indexed array to track parent folders by depth
	eval parent_$depth="$folder"
	# Truncate any deeper levels
	i=$((depth+1))
	while [ "$i" -le 20 ]; do
		eval unset parent_$i
		i=$((i+1))
	done
	# Build path from base_path and all parent_* up to current depth
	path="$base_path"
	if [ "$depth" -ge 0 ]; then
		for i in $(seq 0 $depth); do
			eval pf="\${parent_$i}"
			path="$path/$pf"
		done
	fi

	# Remove base_path from output if requested
	output_path="$path"
	if [ "$no_base_path" -eq 1 ]; then
		output_path="${path#$base_path/}"
	fi

	GREEN="\033[1;32m"
	NC="\033[0m"
	YELLOW_BOLD="\033[1;33m"
	YELLOW_REG="\033[0;33m"
	if [ "$dry_run" -eq 1 ]; then
		if [ -d "$path" ]; then
			printf "${YELLOW_BOLD}SKIP:${NC} %s ${YELLOW_REG}(already exists)${NC}\n" "$output_path"
			[ -n "$log_file" ] && echo "$timestamp SKIP: $output_path (already exists)" >> "$log_file"
		else
			printf "${GREEN}CREATE:${NC} %s\n" "$output_path"
			[ -n "$log_file" ] && echo "$timestamp CREATE: $output_path" >> "$log_file"
		fi
	else
		if [ -d "$path" ]; then
			printf "${YELLOW_BOLD}SKIPPED:${NC} %s ${YELLOW_REG}(already exists)${NC}\n" "$output_path"
			[ -n "$log_file" ] && echo "$timestamp SKIPPED: $output_path (already exists)" >> "$log_file"
			continue
		fi
		mkdir -p "$path"
		printf "${GREEN}CREATED:${NC} %s\n" "$output_path"
		[ -n "$log_file" ] && echo "$timestamp CREATED: $output_path" >> "$log_file"
	fi

done < "$input_file"
