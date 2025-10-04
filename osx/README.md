# macOS Developer Environment Setup

This directory contains scripts for setting up a complete development environment on macOS using Homebrew as the package manager.

## Quick Start

1. **Clone the repository** (if you haven't already):
   ```bash
   git clone <repository-url>
   cd dev-env-setup
   ```

2. **Configure your settings** in `bootstrap.yaml` (see Configuration section below)

3. **Run the setup**:
   ```bash
   cd osx
   ./setup.sh
   ```

4. **To remove everything** (optional):
   ```bash
   ./teardown.sh
   ```

## What Gets Installed

The setup script will install and configure:

### Package Managers
- **Homebrew** - macOS package manager
- **NVM** - Node Version Manager
- **Yarn** - Node.js package manager
- **pnpm** - Fast, disk space efficient package manager

### Development Tools
- **Git** - Version control (pre-installed, just configured)
- **Zed** - Modern code editor
- **Cursor** - AI-powered code editor
- **Visual Studio Code** - Popular code editor
- **iTerm2** - Terminal emulator

### Security Tools
- **mkcert** - Local development certificates

### Communication Tools
- **Slack** - Team communication
- **Zoom** - Video conferencing
- **Microsoft Teams** - Collaboration platform

## Configuration

The setup process is driven by a centralized YAML configuration file (`bootstrap.yaml`) in the project root that allows you to customize which applications and tools are installed. This makes it easy to:

- Add or remove applications without modifying shell scripts
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

Packages can be configured in two ways:

**Simple packages** (just install):
```yaml
packages:
  - vscode
  - slack
```

**Advanced packages** (with configuration):
```yaml
packages:
  - name: git
    install: false  # Skip installation, just configure
    run: |
      git config --global user.name "Your Name"
      git config --global user.email "your_email@example.com"
```

### Customizing Your Setup

1. Edit `bootstrap.yaml` in the project root to modify the applications list to match your needs
2. Run the setup script

### Git Configuration

The setup automatically configures Git with your personal settings. **Important**: Before running the setup, you should update the Git configuration in `bootstrap.yaml` with your own information:

```yaml
packages:
  - name: git
    run: |
      git config --global user.name "John Doe"  # Replace with your name
      git config --global user.email "john.doe@example.com"  # Replace with your email
      git config --global init.defaultBranch main
      git config --global push.autoSetupRemote true

platforms:
  osx:
    packages:
      - name: git
        install: false  # Git is pre-installed on macOS
        run: |
          # macOS-specific Git configuration (if needed)
          # Global config will be applied first
```

#### Required Changes
- **`user.name`**: Replace with your actual name
- **`user.email`**: Replace with your actual email address

## Prerequisites

- **macOS** (tested on macOS 10.15+)
- **Command Line Tools** (will be installed automatically if missing)
- **Internet connection** for downloading packages

## How It Works

1. **Configuration Loading**: Loads `bootstrap.yaml` from the project root
2. **Package Merging**: Combines global packages with macOS-specific packages
3. **Homebrew Installation**: Installs Homebrew if not present
4. **Package Installation**: Installs packages using Homebrew (formulas and casks)
5. **Configuration**: Runs post-installation configuration commands
6. **Git Setup**: Configures Git with your personal settings
7. **NVM Setup**: Installs and configures Node Version Manager

## Troubleshooting

### Permission Issues
If you encounter permission issues, you may need to run:
```bash
sudo chmod +x setup.sh teardown.sh
```

### Homebrew Issues
If Homebrew installation fails, try:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Package Installation Failures
Some packages might fail to install due to:
- Network issues
- Package conflicts
- Missing dependencies

The script will continue with other packages and show warnings for failed installations.

## Teardown

To remove all installed packages and configurations:

```bash
./teardown.sh
```

**Note**: The teardown script will only remove packages that were installed by this setup script. It will preserve:
- Homebrew itself
- Any packages you installed independently
- Your personal files and configurations

## Customization

### Adding New Packages

To add a new package, edit `bootstrap.yaml`:

```yaml
packages:
  - your-new-package
```

Or for packages with configuration:

```yaml
packages:
  - name: your-new-package
    run: |
      # Configuration commands
      your-package --configure
```

### Platform-Specific Packages

To add macOS-specific packages:

```yaml
platforms:
  osx:
    packages:
      - name: macos-specific-tool
        run: |
          # macOS-specific configuration
```

## Contributing

When adding new packages or features:

1. Test on a clean macOS system
2. Update this README if needed
3. Ensure the package works with both Homebrew formulas and casks
4. Add appropriate error handling

## License

This project is licensed under the same terms as the main repository.
