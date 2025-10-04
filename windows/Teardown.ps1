#!/usr/bin/env pwsh
# Windows Developer Environment Teardown

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

Write-Host "=== Uninstall Windows Developer Environment Setup ==="
Write-Host "This script will remove packages and configurations installed by this dev-env-setup."
Write-Host ""

# Load Configuration
$bootstrapConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "bootstrap.yaml"

if (-not (Test-Path $bootstrapConfigPath)) {
    Write-Error "Bootstrap configuration file not found: $bootstrapConfigPath"
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

# Add Windows-specific packages
if ($bootstrapConfig.platforms.windows.packages) {
    $packages += $bootstrapConfig.platforms.windows.packages
}

Write-Host "Configuration loaded successfully"

# Get installed packages
$installedPackages = @()
if (Test-CommandExists scoop) {
    try {
        $scoopList = scoop list 2>$null
        if ($scoopList) {
            $installedPackages = $scoopList | ForEach-Object { $_.Name }
        }
    } catch {
        Write-Warning "Could not get list of installed packages"
    }
}

Write-Host "Found $($installedPackages.Count) installed packages"

# Uninstall packages
Write-Host "Uninstalling packages..."
foreach($package in $packages) {
    if ($package -is [string]) {
        $packageName = $package
        $shouldUninstall = $true
    } else {
        $packageName = $package.name
        $shouldUninstall = $package.install -ne $false
    }
    
    if (-not $shouldUninstall) {
        Write-Host "Skipping uninstallation of $packageName (was not installed by setup)"
    } elseif ($installedPackages -contains $packageName) {
        Write-Host "Uninstalling $packageName..."
        scoop uninstall $packageName --purge
        if($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to uninstall $packageName"
        } else {
            Write-Host "Successfully uninstalled $packageName"
        }
    } else {
        Write-Host "$packageName is not installed"
    }
}

# Clean up SSH config (reverse of setup)
if ($bootstrapConfig.platforms.windows.sshAgent.enabled) {
    Write-Host "Cleaning up SSH configuration..."
    $sshConfigPath = "$HOME\.ssh\config"
    if (Test-Path $sshConfigPath) {
        try {
            $content = Get-Content $sshConfigPath -Raw
            # Check if this is the config created by our setup script
            if ($content -match "AddKeysToAgent yes" -and $content -match "IdentitiesOnly yes" -and $content -match "Host \*") {
                Write-Host "Removing SSH configuration created by setup..."
                Remove-Item $sshConfigPath -Force
                Write-Host "SSH configuration removed"
            } else {
                Write-Host "SSH config exists but was not created by this setup - leaving it alone"
            }
        } catch {
            Write-Warning "Failed to clean up SSH configuration: $($_.Exception.Message)"
        }
    } else {
        Write-Host "No SSH config file found"
    }
} else {
    Write-Host "SSH agent was not configured by setup - skipping cleanup"
}

# Clean up git configuration (reverse of setup)
Write-Host "Cleaning up git configuration..."
try {
    # Check if git config was set by our setup
    $gitName = git config --global user.name 2>$null
    $gitEmail = git config --global user.email 2>$null
    
    if ($gitName -or $gitEmail) {
        Write-Host "Resetting git global configuration..."
        if ($gitName) {
            git config --global --unset user.name
            Write-Host "Removed git user.name"
        }
        if ($gitEmail) {
            git config --global --unset user.email
            Write-Host "Removed git user.email"
        }
        git config --global --unset init.defaultBranch
        git config --global --unset push.autoSetupRemote
        git config --global --unset core.sshCommand
        Write-Host "Git configuration reset"
    } else {
        Write-Host "No git configuration found to reset"
    }
} catch {
    Write-Warning "Failed to reset git configuration: $($_.Exception.Message)"
}

Write-Host "=== Uninstall Complete ==="
Write-Host "Packages installed by this dev-env-setup have been removed."
Write-Host "Scoop package manager and other packages are preserved."