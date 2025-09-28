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

## Configuration

The installation process is now driven by a JSON configuration file (`config.json`) that allows you to customize which applications and tools are installed. This makes it easy to:

- Add or remove applications without modifying PowerShell scripts
- Create different configurations for different environments
- Track configuration changes in version control
- Share configurations with team members

### Configuration Structure

The `config.json` file supports the following sections:

- **`buckets`**: Array of Scoop buckets to add (e.g., "extras", "main")
- **`dependencies`**: Required system dependencies (supports optional `category` field for grouping)
- **`devDependencies`**: Development tools and applications (supports optional `category` field for grouping)
- **`system`**: System configuration options (SSH, Git, etc.)

### Available Categories

- **`version-control`**: Git and version control tools
- **`system-tools`**: System utilities and administration tools
- **`runtime-managers`**: Language and runtime version managers
- **`security-tools`**: Security and certificate management tools
- **`package-managers`**: Package and dependency management tools
- **`code-editors`**: Code editors and IDEs
- **`containerization`**: Docker and containerization tools
- **`api-tools`**: API development and testing tools

### Customizing Your Setup

1. Edit `config.json` to modify the applications list to match your needs
2. Run the installation script

## Default Applications

### Dependencies

#### Version Control
- `git-with-openssh` - Used by Scoop to carry out various actions, such as adding [buckets](https://scoop.sh/#/buckets)

#### System Tools
- `sudo` - Used for requesting elevated (Administrator) privileges required by certain tasks

### DevDependencies

#### Runtime Managers
- `nvm` - Node version management utility for Windows

#### Security Tools
- `mkcert` - A simple zero-config tool to make locally trusted development certificates

#### Package Managers
- `yarn` - Node.js dependency manager

#### Code Editors
- `vscode` - Lightweight but powerful source code editor
- `zed` - Zed code editor
- `cursor` - Cursor AI-powered code editor
