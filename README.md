# Developer Environment Automated Setup

This repository contains scripts for quick and easy setup of your local machine as a development environment using a centralized configuration approach.

## Features

- **Cross-platform**: Works on both Windows and macOS
- **Centralized Configuration**: Single `bootstrap.yaml` file for all platforms
- **Smart Package Management**: Handles both installation and configuration with intelligent updates
- **Flexible Configuration**: Support for simple packages and advanced configuration
- **Easy Customization**: Modify packages and settings without touching scripts
- **Intelligent Installation**: Checks for existing packages and updates them instead of reinstalling
- **Bucket Management**: Automatically checks and adds required package manager buckets

## Supported Platforms

- [**Windows**](./windows/README.md) - Uses Scoop package manager
- [**macOS**](./osx/README.md) - Uses Homebrew package manager

## Quick Start

1. **Clone this repository**:
   ```bash
   git clone <repository-url>
   cd dev-env-setup
   ```

2. **Configure your settings** in `bootstrap.yaml` (see Configuration section below)

3. **Run the setup for your platform**:
   
   **Windows**:
   ```powershell
   cd windows
   .\Setup.ps1
   ```
   
   **macOS**:
   ```bash
   cd osx
   ./setup.sh
   ```

## Configuration

All configuration is centralized in the `bootstrap.yaml` file in the project root. This allows you to:

- Configure packages once for all platforms
- Override settings per platform
- Track changes in version control
- Share configurations with your team

### Basic Structure

```yaml
# Global packages (applied to all platforms)
packages:
  - name: git
    run: |
      git config --global user.name "Your Name"
      git config --global user.email "your_email@example.com"
  - vscode
  - slack

# Platform-specific configurations
platforms:
  windows:
    packages:
      - name: git
        run: |
          git config --global core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe
    sshAgent:
      enabled: true
      autoStart: true
  
  osx:
    packages:
      - name: git
        install: false  # Git is pre-installed on macOS
    # macOS-specific settings...
```

### Package Types

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

### Customization

1. Edit `bootstrap.yaml` to match your needs
2. Run the setup script for your platform
3. The script will automatically merge global and platform-specific settings

## Teardown

To remove all installed packages and configurations:

**Windows**:
```powershell
cd windows
.\Teardown.ps1
```

**macOS**:
```bash
cd osx
./teardown.sh
```

**Note**: Teardown scripts will only remove packages that were installed by this setup. They will preserve:
- Package managers (Scoop/Homebrew)
- Any packages you installed independently
- Your personal files and configurations

## SSH Configuration

You can find more information on generating ssh keys [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

Generate an ssh key (if you do not have one already)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# legacy ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Add key to ssh agent

```bash
ssh-add ~/.ssh/id_ed25519
```

## Project Structure

```
dev-env-setup/
├── bootstrap.yaml          # Centralized configuration file
├── README.md              # This file
├── windows/               # Windows-specific scripts
│   ├── Setup.ps1         # Windows setup script
│   ├── Teardown.ps1      # Windows teardown script
│   ├── README.md         # Windows documentation
│   └── actions/          # PowerShell helper modules
└── osx/                  # macOS-specific scripts
    ├── setup.sh          # macOS setup script
    ├── teardown.sh       # macOS teardown script
    └── README.md         # macOS documentation
```

## Key Features

- **🔄 Smart Merging**: Automatically combines global and platform-specific configurations
- **📦 Package Management**: Supports both simple packages and advanced configuration
- **⚙️ Post-Install Configuration**: Run custom commands after package installation
- **🔧 Cross-Platform**: Same configuration works on Windows and macOS
- **🛡️ Safe Teardown**: Only removes packages installed by this setup
- **📝 Well Documented**: Comprehensive documentation for both platforms
- **🔄 Intelligent Updates**: Checks for existing packages and updates them instead of reinstalling
- **📦 Bucket Management**: Automatically verifies and adds required package manager buckets

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both Windows and macOS
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.