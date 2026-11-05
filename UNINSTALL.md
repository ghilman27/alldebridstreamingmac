# Uninstall Alldebrid Streaming (macOS)

## Version 1.1.0 and later
1. Quit Chrome (⌘Q).
2. Run this in Terminal:
   ```bash
   sudo bash /Library/AlldebridStreaming/uninstall.sh
   ```
3. Type `y` when asked. Add `-y` to the command to skip the question.
4. Check that it's gone. Both commands should print "No such file or directory":
   ```bash
   ls /Library/AlldebridStreaming
   ls /Library/Google/Chrome/NativeMessagingHosts/com.alld.node.json
   ```

### What the uninstaller removes
- The browser registrations (`com.alld.node.json`) for Chrome, and for Edge and Firefox if they were set up.
  It only deletes a file if it points to `/Library/AlldebridStreaming/run.sh`. A file from anything else is left alone.
- Folders the installer created, and only if they are empty
- `/Library/AlldebridStreaming/`
- The installer's record of the package (`pkgutil --forget org.AlldebridStreaming`)

It never touches your home folder.

## Version 1.0.0, or the old `mac/install.sh` script
These versions put files in your home folder. Remove them with the
[cleanup steps in the README](README.md#1-clean-up-an-older-version-skip-on-a-first-install).
Then remove what the 1.0.0 package left behind:
```bash
sudo rm -rf /Library/AlldebridStreaming/1.0.0
sudo rmdir /Library/AlldebridStreaming 2>/dev/null
sudo rm -f /usr/local/bin/AlldebridStreaming-1.0.0
sudo pkgutil --forget org.AlldebridStreaming.1.0.0 2>/dev/null
```
