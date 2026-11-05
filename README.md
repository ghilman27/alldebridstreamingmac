# ALLDEBRID Streaming Plugin
## for OSX /MAC

There is a streaming plugin for Windows and Linux users on the Alldebrid site however no support for mac users

I set about understanding the working of the code made available for windows/linux users, with the view to producing a working MAC version of the code.

I have totally overhauled the original script installation process to use bash rather than javascript and I've bundled it all up in a nice gui installer

Credits to Andy Portmen and Alldebrid for the framework of code necessary to make this work.

![image](https://user-images.githubusercontent.com/118494245/227746452-be0628a1-6828-405e-9f92-59e1c6a8ce00.png)

---

## Dependencies
Install these before running the installer:

| Dependency | Why it's needed | How to get it |
|---|---|---|
| macOS (Intel or Apple Silicon) | Runs the installer | — |
| [Google Chrome](https://www.google.com/chrome/) | The browser the plugin works with | google.com/chrome |
| Alldebrid browser extension | Sends the stream to the helper | Chrome Web Store |
| [VLC](https://www.videolan.org/vlc/) | Plays the stream | videolan.org, installed in `/Applications` (the default) |
| [Node.js](https://nodejs.org) 6 or newer | Runs the helper program (`host.js`) | The nodejs.org installer, `brew install node`, or nvm |

There are no npm packages to install: the helper only uses modules built into Node.

To check that Node is installed, run this in Terminal. It should print a version number:
```bash
node -v
```

If you install Node in a non-standard place, the helper won't find it. It looks in
`/opt/homebrew/bin`, `/usr/local/bin`, `~/.volta/bin` and `~/.nvm` (newest version).

## 1. Clean up an older version (skip on a first install)
Version 1.0.0 and the old `mac/install.sh` script put files in your home folder. Chrome reads those
files before the new ones, so remove them first.

1. Quit Chrome completely (⌘Q).
2. Run these in Terminal. Files that don't exist are skipped, and `rmdir` only deletes folders that are empty.
   ```bash
   # Old browser registrations
   rm -f ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.alld.node.json
   rm -f ~/Library/Application\ Support/Chromium/NativeMessagingHosts/com.alld.node.json
   rm -f ~/Library/Application\ Support/Vivaldi/NativeMessagingHosts/com.alld.node.json
   rm -f ~/Library/Application\ Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.alld.node.json
   rm -f ~/Library/Application\ Support/Microsoft\ Edge/NativeMessagingHosts/com.alld.node.json

   # Empty folders the old script created for browsers you may not have
   rmdir ~/Library/Application\ Support/Chromium/NativeMessagingHosts ~/Library/Application\ Support/Chromium 2>/dev/null
   rmdir ~/Library/Application\ Support/Vivaldi/NativeMessagingHosts ~/Library/Application\ Support/Vivaldi 2>/dev/null

   # Old program folders
   rm -rf ~/com.alld.node ~/.config/com.alld.node
   ```
3. If the first command says **"Operation not permitted"**, macOS is protecting Chrome's folder.
   Delete the file in Finder instead:
   - Press ⌘⇧G and paste `~/Library/Application Support/Google/Chrome/NativeMessagingHosts`.
   - Move `com.alld.node.json` to the Trash. Leave the other files in that folder alone.
4. Check that it's gone. This should print "No such file or directory":
   ```bash
   ls ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.alld.node.json
   ```

## 2. Install
1. Download [AlldebridStreaming.pkg](AlldebridStreaming.pkg) and double-click it.
2. Follow the steps. It asks for your password near the end.
   - If macOS says it **can't verify the developer**, open **System Settings → Privacy & Security**,
     scroll down and click **Open Anyway**. This appears because the package isn't signed.
3. Quit Chrome (⌘Q) and open it again.
4. Stream a link from Alldebrid to VLC.

### Check the installation
```bash
cat /Library/Google/Chrome/NativeMessagingHosts/com.alld.node.json
```
The output should contain `"path": "/Library/AlldebridStreaming/run.sh"`.

### What gets installed
| Location | What |
|---|---|
| `/Library/AlldebridStreaming/` | The helper program (`host.js`, `messaging.js`, `run.sh`) and `uninstall.sh` |
| `/Library/Google/Chrome/NativeMessagingHosts/com.alld.node.json` | Tells Chrome where the helper is |
| `/Library/Microsoft/Edge/NativeMessagingHosts/com.alld.node.json` | Only if Microsoft Edge is installed |
| `/Library/Application Support/Mozilla/NativeMessagingHosts/com.alld.node.json` | Only if Firefox is installed |

Nothing is written to your home folder. Recent macOS versions block other apps from writing into
`~/Library/Application Support/Google/Chrome`, so installing for all users in `/Library` avoids that.

## Troubleshooting
- **Nothing happens when streaming:** make sure Chrome was fully quit (⌘Q) after installing, then repeat the check in step 4 of the cleanup.
- **Node not found:** `run.sh` looks for Node in `/opt/homebrew/bin`, `/usr/local/bin`, `~/.volta/bin` and `~/.nvm` (newest version). Install Node in one of those places.
- **Installation failed:** the details are in the installer log:
  ```bash
  grep -i alldebrid /var/log/install.log | tail -40
  ```
- **See why Chrome can't start the helper:**
  ```bash
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --enable-logging=stderr --v=1 2>&1 | grep -i "native\|alld"
  ```

## 3. Uninstall
See [UNINSTALL.md](UNINSTALL.md). In short:
```bash
sudo bash /Library/AlldebridStreaming/uninstall.sh
```

## Building the installer (for developers)
```bash
bash installer/build.sh
```
This writes `AlldebridStreaming.pkg` to the repo root. The installer sources are in [installer/](installer/):
- `files/`: what gets installed
- `scripts/postinstall`: registers the browsers
- `resources/`: the installer's welcome and finish pages
