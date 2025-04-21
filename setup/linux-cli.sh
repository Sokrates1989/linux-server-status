#!/bin/bash

set -e

echo ""
echo "🛠️  Installing 'server-info' (Linux Server Status CLI)"
echo "======================================================"

# Step 1: Create target directory and clone linux-server-status
if [[ ! -d ~/tools/linux-server-status/.git ]]; then
  echo "🔧 Cloning linux-server-status..."
  mkdir -p ~/tools/linux-server-status
  cd ~/tools/linux-server-status
  git clone https://github.com/Sokrates1989/linux-server-status.git .
else
  echo "ℹ️  linux-server-status already cloned – skipping git clone."
  cd ~/tools/linux-server-status
fi

# Step 2: Ensure script is executable
chmod +x ~/tools/linux-server-status/get_info.sh

# Step 3: Create local bin directory if needed
mkdir -p ~/.local/bin

# Step 4: Create symlink
ln -sf ~/tools/linux-server-status/get_info.sh ~/.local/bin/server-info
echo "✅ Shortcut 'server-info' created in ~/.local/bin"

# Step 5: Add ~/.local/bin to PATH persistently and immediately
EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'

append_export_line() {
  local file="$1"
  if [ -f "$file" ]; then
    if ! grep -Fxq "$EXPORT_LINE" "$file"; then
      echo "$EXPORT_LINE" >> "$file"
      echo "✅ Added PATH update to $file"
    else
      echo "ℹ️  PATH already set in $file"
    fi
  fi
}

append_export_line "$HOME/.bashrc"
append_export_line "$HOME/.profile"

# Export for current shell
export PATH="$HOME/.local/bin:$PATH"

echo ""
echo "🚀 All set! You can now launch the Linux Server Status tool from any terminal with:"
echo ""
echo "   server-info"
echo ""
echo "🧩 If 'server-info' is not recognized yet, you can try the following to make it work immediately:"
echo '   export PATH="$HOME/.local/bin:$PATH"; hash -r'
