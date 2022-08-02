# Develeoper Environement Automated Setup

This repository contains scripts allowing for quicker and easier setup of your local machine's development environmen. It automatically installs and sets up core apps and packages

## Windows

Apps are installed and managed via [scoop](https://scoop.sh).

### `dependencies`

These are applications required by `scoop`. These dependencies allow it to take various actions such as adding `buckets` or requesting `elevated privelages` on a particular command

- `git-with-openssh` - Includes `bash.exe`
- `sudo` - Used to prompt user for elevated (Administrator) privelages if required by a particular apps configuration

### `devDependencies`

These applications are installed and configured using the [`apps.json`](windows/apps.json) file

### Installed By Default

- `7zip`
- `curl`
- `mkcert`
- `nvm`
- `slack`
- `vscode`
- `windows-terminal`
- `yarn`

### Optional

- `android-sdk`
- `android-studio`
- `docker-compose`
- `docker`
- `microsoft-teams`
- `spotify`
- `teamviewer`
- `unity-hub-np`

### Installation

1. Right click and "Run as Administrator"

## OSX

- TODO
