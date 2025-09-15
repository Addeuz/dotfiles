cat-file() {
  local file=""

  # Get the file argument
  file="$1"

  # Check if file argument is provided
  if [[ -z "$file" ]]; then
    echo "Error: File argument is required"
    echo "Usage: cat-file <file>"
    return 1
  fi

  # Check if file exists
  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' does not exist"
    return 1
  fi

  # Check if it's readable
  if [[ ! -r "$file" ]]; then
    echo "Error: File '$file' is not readable"
    return 1
  fi

  # Display file with header
  echo -e "\n## File: $file\n"
  cat "$file"
}
