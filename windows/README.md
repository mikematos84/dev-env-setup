[home](../README.md) / Windows
# Windows

This setup makes use of the Windows-based package manager, [Scoop](https://scoop.sh).

## Prerequisites

### System Requirements
- Windows 10 version 1809 or later, or Windows 11
- PowerShell 5.1 or later
- Administrator privileges (for some operations)
- Internet connection

### OpenSSH Installation
The setup requires OpenSSH for Windows. If not already installed, you may need to install it manually:

1. Run PowerShell as Administrator
2. Install OpenSSH Client: `Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0`
3. Install OpenSSH Server (optional): `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
4. Restart your terminal after installation

### PowerShell Execution Policy
The script will prompt you to set the execution policy to `RemoteSigned` for the current user. This is required for Scoop installation.

## Pre-Install
1. If you have not created any public or private keys, see the [SSH Configuration](../README.md/#ssh-configuration) for more information before moving onto the next step
2. Place any public (`*.pub`) and private keys in the `.ssh` folder (`C:/Users/<username>/.ssh`). If the folder does not exist, create it. 

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

### Customizing Your Setup

1. Edit `config.json` to modify the applications list to match your needs
2. Run the installation script

### Git Configuration

The setup automatically configures Git with your personal settings. **Important**: Before running the installation, you should update the Git configuration in `config.json` with your own information:

```json
{
  "system": {
    "git": {
      "configureSSH": true,
      "description": "Configure Git with SSH integration and custom settings",
      "config": {
        "global": {
          "init": {
            "defaultBranch": "main"
          },
          "user": {
            "name": "Your Name Here",
            "email": "your.email@example.com"
          },
          "core": {
            "sshCommand": "C:/Windows/System32/OpenSSH/ssh.exe"
          },
          "push": {
            "autoSetupRemote": true
          }
        }
      }
    }
  }
}
```

#### Required Changes
- **`user.name`**: Replace with your actual name
- **`user.email`**: Replace with your actual email address

#### Optional Settings
- **`init.defaultBranch`**: Default branch name for new repositories (defaults to "main")
- **`core.sshCommand`**: SSH command path (usually doesn't need changing)
- **`push.autoSetupRemote`**: Automatically set up remote tracking (recommended: true)
- **`configureSSH`**: Enable/disable SSH integration (recommended: true)

The script will automatically apply these settings to your global Git configuration during installation.

## Default Applications

### Dependencies

#### Version Control
- [`git-with-openssh`](https://scoop.sh/#/apps?q=git-with-openssh) - Used by Scoop to carry out various actions, such as adding [buckets](https://scoop.sh/#/buckets)

#### System Tools
- [`sudo`](https://scoop.sh/#/apps?q=sudo) - Used for requesting elevated (Administrator) privileges required by certain tasks

### DevDependencies

#### Runtime Managers
- [`nvm`](https://scoop.sh/#/apps?q=nvm) - Node version management utility for Windows (required)

#### Security Tools
- [`mkcert`](https://scoop.sh/#/apps?q=mkcert) - A simple zero-config tool to make locally trusted development certificates (optional)

#### Package Managers
- [`yarn`](https://scoop.sh/#/apps?q=yarn) - Node.js dependency manager (optional)
- [`pnpm`](https://scoop.sh/#/apps?q=pnpm) - Fast, disk space efficient package manager for Node.js (required)

#### Code Editors
- [`vscode`](https://scoop.sh/#/apps?q=vscode) - Visual Studio Code editor (optional)
- [`zed`](https://scoop.sh/#/apps?q=zed) - Zed code editor (optional)
- [`cursor`](https://scoop.sh/#/apps?q=cursor) - Cursor AI-powered code editor (required)

## Troubleshooting

### Common Issues

#### SSH Agent Service Not Found
If you encounter "SSH Agent service not found" errors:
1. Ensure OpenSSH is installed (see Prerequisites section)
2. Restart your terminal after installing OpenSSH
3. Run the installation script again

#### PowerShell Execution Policy Errors
If you get execution policy errors:
1. Run PowerShell as Administrator
2. Set execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force`
3. Try running the script again

#### Scoop Installation Fails
If Scoop installation fails:
1. Check your internet connection
2. Try running PowerShell as Administrator
3. Ensure Windows Defender or antivirus isn't blocking the installation

#### Git SSH Configuration Issues
If Git SSH doesn't work properly:
1. Verify SSH keys are in `C:/Users/<username>/.ssh/`
2. Check that the SSH config file was created: `C:/Users/<username>/.ssh/config`
3. Test SSH connection: `ssh -T git@github.com`
