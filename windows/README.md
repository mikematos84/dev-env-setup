# Windows Developer Environment Setup

This directory contains scripts for setting up a complete development environment on Windows using Scoop as the package manager.

## Quick Start

1. **Clone the repository** (if you haven't already):
   ```powershell
   git clone <repository-url>
   cd dev-env-setup
   ```

2. **Configure your settings** in `bootstrap.yaml` (see Configuration section below)

3. **Run the setup**:
   ```powershell
   cd windows
   .\Setup.ps1
   ```

4. **To remove everything** (optional):
   ```powershell
   .\Teardown.ps1
   ```

## What Gets Installed

The setup script will install and configure:

### Package Managers
- **Scoop** - Windows package manager
- **NVM** - Node Version Manager
- **Yarn** - Node.js package manager
- **pnpm** - Fast, disk space efficient package manager

### Development Tools
- **Git** - Version control (with SSH configuration)
- **Zed** - Modern code editor
- **Cursor** - AI-powered code editor
- **Visual Studio Code** - Popular code editor

### Security Tools
- **mkcert** - Local development certificates

### Communication Tools
- **Slack** - Team communication
- **Zoom** - Video conferencing
- **Microsoft Teams** - Collaboration platform

## Configuration

The setup process is driven by a centralized YAML configuration file (`bootstrap.yaml`) in the project root that allows you to customize which applications and tools are installed. This makes it easy to:

- Add or remove applications without modifying PowerShell scripts
- Create different configurations for different environments
- Track configuration changes in version control
- Share configurations with team members
- Use the same configuration across Windows and macOS platforms

### Configuration Structure

The `bootstrap.yaml` file supports the following sections:

- **`packages`**: Global packages that apply to all platforms (can be simple strings or objects with `name`, `run`, `install` properties)
- **`platforms`**: Platform-specific configurations
  - **`windows`**: Windows-specific packages and settings
  - **`osx`**: macOS-specific packages and settings
- **`sshAgent`**: SSH agent configuration (platform-specific)
- **`git`**: Git configuration (platform-specific)

### Package Configuration

The configuration uses a simple structure with separate sections for packages and configurations:

**Simple packages** (just install):
```yaml
packages:
  - nvm
  - yarn
  - pnpm
  - zed
  - cursor
  - mkcert
  - slack
  - zoom
  - microsoft-teams
```

**Configuration sections** (separate from packages):
```yaml
configs:
  git:
    run: |
      git config --global user.email "you@example.com"
      git config --global user.name "Your Name"
      git config --global init.defaultBranch main
      git config --global push.autoSetupRemote true
```

**Platform-specific packages and configs**:
```yaml
platforms:
  windows:
    packages:
      - vscode
    buckets:
      - extras
    sshAgent:
      enabled: true
      autoStart: true
    configs:
      git:
        run: |
          git config --global core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe
```

### Customizing Your Setup

1. Edit `bootstrap.yaml` in the project root to modify the applications list to match your needs
2. Run the setup script

### Git Configuration

The setup automatically configures Git with your personal settings. **Important**: Before running the setup, you should update the Git configuration in `bootstrap.yaml` with your own information:

```yaml
# Global Git configuration
configs:
  git:
    run: |
      git config --global user.email "you@example.com"  # Replace with your email
      git config --global user.name "Your Name"  # Replace with your name
      git config --global init.defaultBranch main
      git config --global push.autoSetupRemote true

platforms:
  windows:
    configs:
      git:
        run: |
          git config --global core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe
```

#### Required Changes
- **`user.name`**: Replace with your actual name
- **`user.email`**: Replace with your actual email address

## Prerequisites

- **Windows 10** version 1809 or later, or **Windows 11**
- **PowerShell 5.1** or later
- **Internet connection** for downloading packages
- **OpenSSH** (will be installed automatically if missing)

## Smart Installation Features

The setup script includes several intelligent features to make the installation process more efficient and reliable:

### Git Management
- **Automatic Installation**: Git is installed immediately after Scoop to ensure it's available for subsequent operations
- **Update Detection**: If Git is already installed, the script will update it instead of reinstalling
- **Error Handling**: Continues with the setup even if Git installation fails

### Bucket Management
- **Bucket Verification**: Checks if required Scoop buckets are already added before attempting to add them
- **Efficient Processing**: Skips adding buckets that are already present
- **Clear Feedback**: Provides clear messages about bucket status

### Package Installation
- **Update Detection**: Checks if packages are already installed and updates them instead of reinstalling
- **Dependency Management**: Handles package dependencies automatically
- **Error Recovery**: Continues with other packages if one fails to install

## How It Works

1. **Configuration Loading**: Loads `bootstrap.yaml` from the project root
2. **Package Merging**: Combines global packages with Windows-specific packages
3. **Scoop Installation**: Installs Scoop if not present
4. **Git Installation**: Installs or updates Git immediately after Scoop
5. **Bucket Management**: Checks and adds required Scoop buckets
6. **Package Installation**: Installs or updates packages using Scoop (with intelligent checking)
7. **Configuration**: Runs post-installation configuration commands
8. **SSH Setup**: Configures SSH with your keys

## Troubleshooting

### PowerShell Execution Policy Errors
If you get execution policy errors:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Scoop Setup Fails
If Scoop setup fails:
1. Check your internet connection
2. Try running PowerShell as Administrator
3. Ensure Windows Defender or antivirus isn't blocking the setup

### SSH Configuration Issues
If Git SSH doesn't work properly:
1. Verify SSH keys are in `C:/Users/<username>/.ssh/`
2. Check that the SSH config file was created: `C:/Users/<username>/.ssh/config`
3. Test SSH connection: `ssh -T git@github.com`

### Git Installation Issues
If Git installation fails:
1. Check your internet connection
2. Verify Scoop is working: `scoop --version`
3. Try manually installing Git: `scoop install git`
4. The script will continue even if Git installation fails

### Bucket Addition Issues
If bucket addition fails:
1. Check your internet connection
2. Verify Scoop is working: `scoop --version`
3. Try manually adding buckets: `scoop bucket add extras`
4. The script will continue with package installation

## Teardown

To remove all installed packages and configurations:

```powershell
.\Teardown.ps1
```

**Note**: The teardown script will only remove packages that were installed by this setup script. It will preserve:
- Scoop itself
- Any packages you installed independently
- Your personal files and configurations

## Customization

### Adding New Packages

To add a new package, edit `bootstrap.yaml`:

```yaml
packages:
  - your-new-package
```

For packages that need configuration, add them to the configs section:

```yaml
configs:
  your-new-package:
    run: |
      # Configuration commands
      your-package --configure
```

### Platform-Specific Packages

To add Windows-specific packages:

```yaml
platforms:
  windows:
    packages:
      - windows-specific-tool
    configs:
      windows-specific-tool:
        run: |
          # Windows-specific configuration
```

## Contributing

When adding new packages or features:

1. Test on a clean Windows system
2. Update this README if needed
3. Ensure the package works with Scoop
4. Add appropriate error handling

## License

This project is licensed under the same terms as the main repository.