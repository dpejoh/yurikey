#!/system/bin/sh

# Define important paths and file names
TRICKY_DIR="/data/adb/tricky_store"
REMOTE_URL="https://raw.githubusercontent.com/dpejoh/yurikey/main/conf"
TARGET_FILE="$TRICKY_DIR/keybox.xml"
BACKUP_FILE="$TRICKY_DIR/keybox.xml.bak"
TMP_REMOTE="$TRICKY_DIR/remote_keybox.tmp"
SCRIPT_REMOTE="$TRICKY_DIR/remote_script.sh"
DEPENDENCY_MODULE="/data/adb/modules/tricky_store"

# Detailed log
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') [YURI_KEYBOX] $1"
}

log_message "Start"

# Check if Tricky Store module is installed (required dependency)
if [ ! -d "$DEPENDENCY_MODULE" ]; then
  log_message "ERROR: Tricky Store module not found!"
  log_message "Please install Tricky Store before using Yuri Keybox."
  exit 1
fi

# Function to download the remote keybox
fetch_remote_keybox() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REMOTE_URL" | base64 -d > "$SCRIPT_REMOTE"
    chmod +x "$SCRIPT_REMOTE"
    if ! sh "$SCRIPT_REMOTE"; then
      log_message "ERROR: Remote script failed. Aborting."
      return 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$REMOTE_URL" | base64 -d > "$SCRIPT_REMOTE"
    chmod +x "$SCRIPT_REMOTE"
    if ! sh "$SCRIPT_REMOTE"; then
      log_message "ERROR: Remote script failed. Aborting."
      return 1
    fi
  else
    log_message "ERROR: curl or wget not found."
    log_message "Cannot fetch remote keybox."
    log_message "Tip: You can install a working BusyBox with network tools from:"
    log_message "https://mmrl.dev/repository/grdoglgmr/busybox-ndk"
    return 1
  fi
  return 0
}

# Function to update the keybox file
update_keybox() {
  log_message "Writing"
  if ! fetch_remote_keybox; then
    log_message "Failed to fetch writing keybox!"
    return
  fi

  # Check if keybox already exists
  if [ -f "$TARGET_FILE" ]; then
    # If the new one is identical, skip update
    if cmp -s "$TARGET_FILE" "$TMP_REMOTE"; then
      rm -f "$TMP_REMOTE"
      rm -rf "$SCRIPT_REMOTE"
      return
    else
      # If the file differs, back up the old one
      mv "$TARGET_FILE" "$BACKUP_FILE"
      rm -rf "$SCRIPT_REMOTE"
    fi
  fi

  # Move the downloaded keybox into place
  mv "$TMP_REMOTE" "$TARGET_FILE"
  rm -rf "$SCRIPT_REMOTE"
}

# Start main logic
mkdir -p "$TRICKY_DIR" # Make sure the directory exists
update_keybox          # Begin the update process

log_message "Finish"
