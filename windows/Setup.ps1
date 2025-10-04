#!/usr/bin/env pwsh
# Windows Developer Environment Setup

# Simple command existence check
function Test-CommandExists {
    param($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if(Get-Command $command) {
            return $true
        }
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

Write-Host "=== Windows Developer Environment Setup ==="

# Load Configuration
$bootstrapConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "bootstrap.yaml"

if (-not (Test-Path $bootstrapConfigPath)) {
    Write-Error "Bootstrap configuration file not found: $bootstrapConfigPath"
    Write-Host "Please ensure bootstrap.yaml exists in the project root."
    exit 1
}

# Install powershell-yaml module if needed
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Installing powershell-yaml module..."
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser -AllowClobber
}

Import-Module powershell-yaml -Force

# Load and merge configuration
$bootstrapConfig = Get-Content $bootstrapConfigPath -Raw | ConvertFrom-Yaml
$packages = @()

# Add global packages
if ($bootstrapConfig.packages) {
    $packages += $bootstrapConfig.packages
}

# Add Windows-specific packages with deduplication
if ($bootstrapConfig.platforms.windows.packages) {
    foreach($winPackage in $bootstrapConfig.platforms.windows.packages) {
        $winPackageName = if ($winPackage -is [string]) { $winPackage } else { $winPackage.name }
        
        # Check if package already exists
        $existingIndex = -1
        for ($i = 0; $i -lt $packages.Count; $i++) {
            $existingPackage = $packages[$i]
            $existingPackageName = if ($existingPackage -is [string]) { $existingPackage } else { $existingPackage.name }
            if ($existingPackageName -eq $winPackageName) {
                $existingIndex = $i
                break
            }
        }
        
        if ($existingIndex -ge 0) {
            # Replace with Windows-specific version (which may have additional run commands)
            $packages[$existingIndex] = $winPackage
        } else {
            # Add new package
            $packages += $winPackage
        }
    }
}

Write-Host "Configuration loaded successfully"

# Install Scoop if missing
if (-not (Test-CommandExists scoop)) {
    Write-Host "Installing Scoop package manager..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    if($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install Scoop. Please check your internet connection."
        exit 1
    }
}

# Add Scoop buckets immediately after Scoop installation
Write-Host "Adding Scoop buckets..."
$buckets = @("extras")  # Default bucket
if ($bootstrapConfig.platforms.windows.buckets) {
    $buckets = $bootstrapConfig.platforms.windows.buckets
}

foreach($bucket in $buckets) {
    Write-Host "Adding bucket: $bucket"
    scoop bucket add $bucket 2>$null
    if($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to add bucket: $bucket"
    } else {
        Write-Host "Successfully added bucket: $bucket"
    }
}

# Install packages
Write-Host "Installing packages..."
if ($packages) {
    foreach($package in $packages) {
        if ($package -is [string]) {
            $packageName = $package
            $runCommands = $null
            $shouldInstall = $true
        } else {
            $packageName = $package.name
            $runCommands = $package.run
            $shouldInstall = $package.install -ne $false
        }
        
        if (-not $shouldInstall) {
            Write-Host "Skipping installation of $packageName (install: false)"
        } else {
            # Check if package is already installed
            $isInstalled = $false
            try {
                $installedCheck = scoop list $packageName 2>$null
                if ($installedCheck -and $installedCheck -match $packageName) {
                    $isInstalled = $true
                }
            } catch {
                $isInstalled = $false
            }
            
            if ($isInstalled) {
                Write-Host "Updating $packageName..."
                scoop update $packageName
                if($LASTEXITCODE -ne 0) {
                    Write-Warning "Failed to update package: $packageName"
                } else {
                    Write-Host "Successfully updated $packageName"
                }
            } else {
                Write-Host "Installing $packageName..."
                scoop install $packageName
                if($LASTEXITCODE -ne 0) {
                    Write-Warning "Failed to install package: $packageName"
                } else {
                    Write-Host "Successfully installed $packageName"
                }
            }
        }
        
        # Execute run commands if specified
        if ($runCommands) {
            Write-Host "Running post-install commands for $packageName..."
            $commands = $runCommands -split "`n" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -notlike "#*" }
            foreach ($command in $commands) {
                $command = $command.Trim()
                if ($command) {
                    Write-Host "  Executing: $command"
                    Invoke-Expression $command
                    if($LASTEXITCODE -ne 0) {
                        Write-Warning "Command failed: $command"
                    }
                }
            }
        }
    }
} else {
    Write-Host "No packages to install"
}

# Execute global configurations
Write-Host "Executing global configurations..."
if ($bootstrapConfig.configs) {
    foreach($configName in $bootstrapConfig.configs.PSObject.Properties.Name) {
        $config = $bootstrapConfig.configs.$configName
        if ($config.run) {
            Write-Host "Running global config for $configName..."
            $commands = $config.run -split "`n" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -notlike "#*" }
            foreach ($command in $commands) {
                $command = $command.Trim()
                if ($command) {
                    Write-Host "  Executing: $command"
                    Invoke-Expression $command
                    if($LASTEXITCODE -ne 0) {
                        Write-Warning "Command failed: $command"
                    }
                }
            }
        }
    }
}

# Execute platform-specific configurations (can add to or overwrite global configs)
Write-Host "Executing Windows-specific configurations..."
if ($bootstrapConfig.platforms.windows.configs) {
    foreach($configName in $bootstrapConfig.platforms.windows.configs.PSObject.Properties.Name) {
        $config = $bootstrapConfig.platforms.windows.configs.$configName
        if ($config.run) {
            Write-Host "Running Windows-specific config for $configName..."
            $commands = $config.run -split "`n" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -notlike "#*" }
            foreach ($command in $commands) {
                $command = $command.Trim()
                if ($command) {
                    Write-Host "  Executing: $command"
                    Invoke-Expression $command
                    if($LASTEXITCODE -ne 0) {
                        Write-Warning "Command failed: $command"
                    }
                }
            }
        }
    }
}

# Configure SSH if enabled
if ($bootstrapConfig.platforms.windows.sshAgent.enabled) {
    Write-Host "Configuring SSH..."
    
    # Create SSH config
    $sshConfigPath = "$HOME\.ssh\config"
    if (-not (Test-Path (Split-Path $sshConfigPath -Parent))) {
        New-Item -Path (Split-Path $sshConfigPath -Parent) -ItemType Directory -Force | Out-Null
    }
    
    $sshConfig = @"
Host *
  AddKeysToAgent yes
  IdentitiesOnly yes

Host github.com
  Hostname github.com
  User git
"@
    
    # Add SSH keys
    $keys = Get-ChildItem -Path "$HOME\.ssh" -Filter "*.pub" -ErrorAction SilentlyContinue
    if($keys) {
        foreach($key in $keys) {
            $keyName = $key.Name.replace('.pub','')
            $sshConfig += "`n  IdentityFile ~/.ssh/$keyName"
        }
    }
    
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($sshConfigPath, $sshConfig, $utf8NoBom)
    Write-Host "SSH config written to $sshConfigPath"
}

Write-Host "=== Installation Complete ==="
Write-Host "You may need to restart your terminal or run 'refreshenv' to use the newly installed tools."
