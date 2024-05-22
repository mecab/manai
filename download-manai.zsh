#!/usr/bin/env zsh

# Set default version
version="latest"

# Perform confirmation by default
confirm_download=true

# Function to normalize version string
function normalize_version() {
  local ver=$1
  ver=${ver#v.}  # Remove leading "v." from version string
  if [[ "$ver" != v* ]]; then
    ver="v$ver"  # Add leading "v" if not present
  fi
  echo "$ver"
}

# Parse command line arguments
while getopts ":v:y" opt; do
  case $opt in
    v)
      version=$(normalize_version $OPTARG)
      ;;
    y)
      confirm_download=false
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Function to remove temporary directory
function cleanup() {
  if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
    rm -rf "$temp_dir"
  fi
}

# Remove temporary directory on script exit or interruption
trap cleanup EXIT INT TERM

# Function to determine the architecture
function get_architecture() {
  local os=$(uname)
  local arch=$(uname -m)

  if [[ "$os" == "Linux" ]]; then
    if [[ "$arch" == "x86_64" ]]; then
      echo "linux-x64"
    elif [[ "$arch" == "aarch64" ]]; then
      echo "linux-arm64"
    else
      echo "Unsupported architecture: $arch" >&2
      exit 1
    fi
  elif [[ "$os" == "Darwin" ]]; then
    if [[ "$arch" == "x86_64" ]]; then
      echo "darwin-x64"
    elif [[ "$arch" == "arm64" ]]; then
      echo "darwin-arm64"
    else
      echo "Unsupported architecture: $arch" >&2
      exit 1
    fi
  else
    echo "Unsupported operating system: $os" >&2
    exit 1
  fi
}

# Create temporary directory
temp_dir=$(mktemp -d)

# Get the architecture
architecture=$(get_architecture)

# Set the download URL
if [[ "$version" == "latest" ]]; then
  download_url="https://github.com/mecab/manai/releases/latest/download/manai-bun-${architecture}.tar.gz"
else
  download_url="https://github.com/mecab/manai/releases/download/${version}/manai-bun-${architecture}.tar.gz"
fi

# Confirm with the user if needed
if [[ "$confirm_download" == true ]]; then
  echo "Detected architecture: $architecture"
  echo "Download URL: $download_url"
  read "confirm?Do you want to proceed with the download? [y/N]: "

  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Download aborted by the user."
    exit 0
  fi
fi

# Download and extract the executable
curl -L "$download_url" | tar -xz -C "$temp_dir"

# Create the bin directory in the same directory as the script (if it doesn't exist)
script_dir=$(dirname "$0")
bin_dir="$script_dir/bin"
mkdir -p "$bin_dir"

# Copy the manai binary to the bin directory
cp "$temp_dir/bin/manai" "$bin_dir"

echo "manai binary (version: $version) has been successfully downloaded and installed in the bin directory."
