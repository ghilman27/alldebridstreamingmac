#!/bin/bash
# Started by the browser (as the logged-in user) to run the Alldebrid native host.
# Browsers launch this with a minimal PATH, so look for Node in the usual places.

cd "$(dirname "$0")" || exit 1

candidates=(
  /opt/homebrew/bin/node
  /usr/local/bin/node
  "$HOME/.volta/bin/node"
)
# Newest nvm-installed Node, if any
nvm_node=$(ls -d "$HOME"/.nvm/versions/node/*/bin/node 2>/dev/null | sort -V | tail -1)
[ -n "$nvm_node" ] && candidates+=("$nvm_node")

for n in "${candidates[@]}"; do
  if [ -x "$n" ]; then
    exec "$n" host.js
  fi
done

echo "AlldebridStreaming: Node.js not found. Install it from https://nodejs.org" >&2
exit 1
