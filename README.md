# Develeoper Environement Automated Setup

This repository contains scripts allowing for quicker and easier setup of your local machine's development environmen. It automatically installs and sets up core apps and packages

## Windows

Apps are installed and managed via [scoop](https://scoop.sh).

### Prerequisite Apps

These applications are installed by default and are necessary to install further applications using scopp since a base flavor of `git` is required to install other buckets

- `git-with-openssh` - Includes `bash.exe`
- `sudo` - Used to prompt user for elevated (Administrator) privelages if required by a particular apps configuration

### Core Applications

These applications are installed and configured using the [`apps.json`](windows/apps.json) file

- IDE(s) (Integrated Developement Environment(s)
  - vscode
- Music
  - spotify
- Utilities
  - 7zip
  - curl
  - sudo
- Web Development
  - nvm
  - mkcert
  - yarn

### Installation

1. Right click and "Run as Administrator"

## OSX

- TODO
