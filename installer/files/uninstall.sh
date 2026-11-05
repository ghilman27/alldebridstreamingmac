#!/bin/bash
# Removes AlldebridStreaming. Usage: sudo bash /Library/AlldebridStreaming/uninstall.sh [-y]
#
# Only removes what the installer created:
#   - manifests listed in .installed-manifests that still point to our run.sh
#   - folders listed in .created-dirs, and only if they are empty
#   - the known files in /Library/AlldebridStreaming
# It never touches your home folder.

APP_DIR="/Library/AlldebridStreaming"
HOST="com.alld.node"
OUR_PATH="$APP_DIR/run.sh"
PKG_ID="org.AlldebridStreaming"

if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo: sudo bash $APP_DIR/uninstall.sh"
  exit 1
fi

if [ "$1" != "-y" ]; then
  read -r -p "Remove AlldebridStreaming? [y/N] " answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 0 ;; esac
fi

# 1. Browser manifests (recorded list plus the standard locations, in case the list is missing)
manifests=()
[ -f "$APP_DIR/.installed-manifests" ] && while IFS= read -r line; do manifests+=("$line"); done < "$APP_DIR/.installed-manifests"
manifests+=(
  "/Library/Google/Chrome/NativeMessagingHosts/$HOST.json"
  "/Library/Microsoft/Edge/NativeMessagingHosts/$HOST.json"
  "/Library/Application Support/Mozilla/NativeMessagingHosts/$HOST.json"
)
seen=$'\n'
for m in "${manifests[@]}"; do
  case "$seen" in *$'\n'"$m"$'\n'*) continue ;; esac
  seen="$seen$m"$'\n'
  [ -f "$m" ] || continue
  if grep -qF "\"$OUR_PATH\"" "$m"; then
    rm -f "$m" && echo "Removed $m"
  else
    echo "Skipped $m (not created by this installer)"
  fi
done

# 2. Folders the installer created, deepest first; rmdir only removes empty folders
if [ -f "$APP_DIR/.created-dirs" ]; then
  sort -r "$APP_DIR/.created-dirs" | while IFS= read -r d; do
    case "$d" in /Library/*) ;; *) continue ;; esac
    [ -d "$d" ] && rmdir "$d" 2>/dev/null && echo "Removed empty folder $d"
  done
fi

# 3. Program files
for f in host.js messaging.js run.sh uninstall.sh "$HOST.chrome.json" "$HOST.firefox.json" .installed-manifests .created-dirs; do
  rm -f "$APP_DIR/$f"
done
if rmdir "$APP_DIR" 2>/dev/null; then
  echo "Removed $APP_DIR"
elif [ -d "$APP_DIR" ]; then
  echo "Left $APP_DIR in place because it contains files this uninstaller doesn't know about."
fi

# 4. Installer receipts (the old 1.0.0 one too, if present)
pkgutil --forget "$PKG_ID" >/dev/null 2>&1 && echo "Removed installer receipt $PKG_ID"
pkgutil --forget "$PKG_ID.1.0.0" >/dev/null 2>&1

echo "AlldebridStreaming is uninstalled. Restart your browser."
exit 0
