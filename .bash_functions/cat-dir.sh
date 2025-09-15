cat-dir() {
  local dir=""
  local depth=5                # Default max depth is 5

  # Check if depth flag (-d) is passed
  while getopts "d:" opt; do
    case $opt in
      d) depth=$OPTARG;;
    esac
  done

  # Shift positional arguments to handle cases when -d is present
  shift $((OPTIND - 1))

  # Get the directory argument after processing options
  dir="$1"

  # Check if directory argument is provided
  if [[ -z "$dir" ]]; then
    echo "Error: Directory argument is required"
    echo "Usage: cat-dir [-d depth] <directory>"
    return 1
  fi

  # Check if directory exists
  if [[ ! -d "$dir" ]]; then
    echo "Error: Directory '$dir' does not exist"
    return 1
  fi

  # Execute find command to concatenate files with path header
  find "$dir" -maxdepth "$depth" -type f | xargs -I {} sh -c 'echo "\n## File: {}" && cat {}'
}
