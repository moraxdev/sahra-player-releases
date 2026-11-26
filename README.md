# Sahra Player releases

Public update feed for Sahra Player. `update.json` tells the installed apps about the current
build. This repository holds built files only; there is no source code or account data here.
Windows builds are verified with an Ed25519 signature, Android builds by the app signing key.

## Installer (for Sahra Hub)
Each Windows release also has an installer in `installers/`, listed as `windows.installer` in
`update.json` and signed with the same key. `publish.py windows …` makes it by itself through
`make_installer.py` (settings in `installer.json`, script `installer.nsi`; needs `makensis`).
It installs per user to `%LOCALAPPDATA%\Programs\Sahra Player`. Older app versions ignore the
new field and keep updating as before.
