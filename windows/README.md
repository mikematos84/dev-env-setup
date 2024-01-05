[home](../README.md) / Windows
# Windows

This setup makes use of the Windows-based package manager, [Scoop](https://scoop.sh).

## Pre-Install
1. If you have not created any public or private keys, see the [SSH Configuration](../README.md/#ssh-configuration) for more information before moving onto the next step
2. Place any public (`*.pub`) and private keys in the `.ssh` folder (`C:/Users/<username>/.ssh`). If the folder so not exist, create it. 

> Make sure to place both the **public** and **private** keys within this folder. The script will look for any public (`*.pub`) keys within this folder and use their base name (`*`) to create the necessary SSH config file


## Install

Right click on **Install.ps1** in the **windows** folder and select **"Run with Powershell"**

## Uninstall

Right click on **Uninstall.ps1** in the **windows** folder and select **"Run with Powershell"**

## dependencies

- `git` - Used by Scoop to cary out various actions, such as adding [buckets](https://scoop.sh/#/buckets). For the purposes of this environment's setup, we will be using [git-with-openssh](https://scoop.sh/#/apps?q=git-with-openssh)
- `sudo` - Used for requesting elevated (Administrator) privelages required by certain tasks

## devDependencies

- `nvm` - Node version managment utility for windows, 
- `vscode` - Lightweight but powerful source code editor
- `mkcert` - A simple zero-config tool to make locally trusted development certificates with any names you'd like
- `yarn` - Node.js dependency manager
