#!/bin/bash

# Get the directory of this script (Contents/MacOS/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Path to the AppleScript inside Resources
AS_FILE="$SCRIPT_DIR/../Resources/main.applescript"

# Execute the AppleScript using osascript
osascript "$AS_FILE"
