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

### Setup SSH

You can find more information on generating ssh keys [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

Generate and ssh key (if you do not have one already)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# legacy ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Add key to ssh agent

```bash
ssh-add ~/.ssh/id_ed25519
```

Create ssh config file

```bash
touch ~/.ssh/config
```

Add the following configuration to the file where `<user>` is your `username`

```txt
Host github.com
  AddKeysToAgent yes
  IdentityFile C:\Users\<user>\.ssh\id_rsa
```

## OSX

- TODO
