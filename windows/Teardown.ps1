# https://github.com/ScoopInstaller/Scoop/wiki/Uninstalling-Scoop

# Import Modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\actions\Test-CommandExists.ps1"
. "$scriptPath\actions\Validate-Configuration.ps1"

Write-Host "=== Uninstall Windows Developer Environment Setup ==="
Write-Host "This script will only remove packages and configurations that were installed by this dev-env-setup."
Write-Host "Scoop and any other packages you installed independently will be preserved."
Write-Host ""

# Load Configuration
function Get-Configuration {
    $configPath = Join-Path $scriptPath "config.yaml"
    if (Test-Path $configPath) {
        try {
            # Ensure powershell-yaml module is available
            if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
                Write-Host "Installing powershell-yaml module..."
                Install-Module -Name powershell-yaml -Force -Scope CurrentUser -AllowClobber
            }
            
            Import-Module powershell-yaml -Force
            $config = Get-Content $configPath -Raw | ConvertFrom-Yaml
            Write-Host "Configuration loaded successfully from $configPath"
            return $config
        } catch {
            Write-Error "Failed to parse configuration file: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Error "Configuration file not found: $configPath"
        Write-Host "Please ensure config.yaml exists in the windows directory."
        exit 1
    }
}


function Get-InstalledPackages {
    try {
        $scoopApps = scoop list 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to get scoop list. Scoop may not be installed or accessible."
            return @()
        }
        
        # Handle both object and string output
        [string[]] $installedApps = @()
        
        if ($scoopApps -is [array]) {
            # If it's an array of objects, extract the Name property
            foreach ($app in $scoopApps) {
                if ($app -and $app.Name) {
                    $installedApps += $app.Name
                }
            }
        } else {
            # If it's a single object, extract its Name property
            if ($scoopApps -and $scoopApps.Name) {
                $installedApps += $scoopApps.Name
            }
        }
        
        Write-Host "Found installed packages: $($installedApps -join ', ')" -ForegroundColor Cyan
        return $installedApps
    } catch {
        Write-Warning "Error getting installed packages: $($_.Exception.Message)"
        return @()
    }
}

function Test-PackageInstalledByScript {
    param(
        [string]$appName,
        [PSCustomObject]$Config
    )
    
    # Check if the package is in our configuration (either dependencies or devDependencies)
    $allConfiguredPackages = @()
    
    if($Config.dependencies) {
        $allConfiguredPackages += $Config.dependencies | ForEach-Object { $_.name }
    }
    
    if($Config.devDependencies) {
        $allConfiguredPackages += $Config.devDependencies | ForEach-Object { $_.name }
    }
    
    return $allConfiguredPackages -contains $appName
}

function Uninstall-App {
    param(
        [string]$appName,
        [string]$description,
        [PSCustomObject]$Config
    )
    
    Write-Host "Checking $appName ($description)..." -ForegroundColor Yellow
    
    $installedApps = Get-InstalledPackages
    
    if(($null -ne $installedApps) -and ($installedApps.Contains($appName))){
        Write-Host "  -> $appName is currently installed" -ForegroundColor Green
        
        # Check if this package was installed by our script
        if(Test-PackageInstalledByScript -appName $appName -Config $Config) {
            Write-Host "  -> $appName was installed by this dev-env-setup" -ForegroundColor Cyan
            Write-Host "Uninstalling $appName ($description)..." -ForegroundColor Red
            
            # Try to uninstall with force flag to handle dependencies
            scoop uninstall $appName --purge
            if($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to uninstall $appName - it may be required by other packages"
                Write-Host "  -> You may need to manually uninstall $appName if it's no longer needed"
                Write-Host "  -> Try running: scoop uninstall $appName --purge" -ForegroundColor Yellow
            } else {
                Write-Host "  -> Successfully uninstalled $appName" -ForegroundColor Green
            }
        } else {
            Write-Host "  -> $appName is installed but was not installed by this dev-env-setup" -ForegroundColor Yellow
            Write-Host "  -> Skipping uninstall to preserve your other packages" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  -> $appName ($description) is not installed" -ForegroundColor Gray
    }
}

function Revert-GitConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    
    Write-Host "=== Reverting Git Configuration ==="
    
    if (-not (Test-CommandExists git)) {
        Write-Host "Git not found, skipping Git configuration revert"
        return
    }
    
    try {
        # Only revert configurations that were set by our install script
        if ($Config.system.git.config.global) {
            $globalConfig = $Config.system.git.config.global
            
            # Revert user information
            if ($globalConfig.user) {
                if ($globalConfig.user.name) {
                    Write-Host "Reverting Git user name..."
                    git config --global --unset user.name 2>$null
                }
                if ($globalConfig.user.email) {
                    Write-Host "Reverting Git user email..."
                    git config --global --unset user.email 2>$null
                }
            }
            
            # Revert init settings
            if ($globalConfig.init) {
                if ($globalConfig.init.defaultBranch) {
                    Write-Host "Reverting default branch setting..."
                    git config --global --unset init.defaultBranch 2>$null
                }
            }
            
            # Revert core settings
            if ($globalConfig.core) {
                if ($globalConfig.core.sshCommand) {
                    Write-Host "Reverting SSH command setting..."
                    git config --global --unset core.sshCommand 2>$null
                }
            }
            
            # Revert push settings
            if ($globalConfig.push) {
                if ($globalConfig.push.autoSetupRemote) {
                    Write-Host "Reverting push auto setup remote setting..."
                    git config --global --unset push.autoSetupRemote 2>$null
                }
            }
            
            Write-Host "Git configuration reverted successfully"
        } else {
            Write-Host "No Git configuration found in config to revert"
        }
        
    } catch {
        Write-Warning "Failed to revert some Git configuration settings: $($_.Exception.Message)"
    }
}

function Revert-SSHConfiguration {
    Write-Host "=== Reverting SSH Configuration ==="
    
    $sshConfigPath = "$HOME\.ssh\config"
    if (Test-Path $sshConfigPath) {
        try {
            $content = Get-Content $sshConfigPath -Raw
            
            # Check if our SSH config exists (look for our specific markers)
            if ($content -match "AddKeysToAgent yes" -and $content -match "IdentitiesOnly yes") {
                Write-Host "Removing our SSH configuration from $sshConfigPath..."
                
                # Remove our specific SSH config block
                $newContent = $content -replace "(?s)Host \*\s*AddKeysToAgent yes\s*IdentitiesOnly yes\s*Host github\.com\s*Hostname github\.com\s*User git\s*", ""
                
                # Remove any IdentityFile entries we added
                $lines = $newContent -split "`n"
                $filteredLines = @()
                $skipNext = $false
                
                foreach ($line in $lines) {
                    if ($line -match "^\s*IdentityFile\s+~/.ssh/") {
                        Write-Host "Removing IdentityFile entry: $($line.Trim())"
                        continue
                    }
                    $filteredLines += $line
                }
                
                $newContent = $filteredLines -join "`n"
                
                if ($newContent.Trim() -eq "") {
                    # If file is empty after removal, delete it
                    Remove-Item $sshConfigPath -Force
                    Write-Host "SSH config file removed (was empty after cleanup)"
                } else {
                    # Write back the cleaned content
                    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                    [System.IO.File]::WriteAllText($sshConfigPath, $newContent, $utf8NoBom)
                    Write-Host "SSH configuration reverted successfully"
                }
            } else {
                Write-Host "No SSH configuration found that was set by this installer"
            }
        } catch {
            Write-Warning "Failed to revert SSH configuration: $($_.Exception.Message)"
        }
    } else {
        Write-Host "No SSH config file found"
    }
}

function Revert-GitBashConfiguration {
    Write-Host "=== Reverting Git Bash Configuration ==="
    
    $bashrcPath = "$HOME\.bashrc"
    if (Test-Path $bashrcPath) {
        try {
            $content = Get-Content $bashrcPath -Raw
            
            # Check if our Git Bash SSH config exists
            if ($content -match "Configure Git Bash to use Windows SSH agent") {
                Write-Host "Removing Git Bash SSH configuration from .bashrc..."
                
                # Remove our specific SSH configuration block
                $newContent = $content -replace "(?s)# Configure Git Bash to use Windows SSH agent.*?fi\s*\n", ""
                
                if ($newContent.Trim() -eq "") {
                    # If file is empty after removal, delete it
                    Remove-Item $bashrcPath -Force
                    Write-Host ".bashrc file removed (was empty after cleanup)"
                } else {
                    # Write back the cleaned content
                    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                    [System.IO.File]::WriteAllText($bashrcPath, $newContent, $utf8NoBom)
                    Write-Host "Git Bash SSH configuration reverted successfully"
                }
            } else {
                Write-Host "No Git Bash SSH configuration found that was set by this installer"
            }
        } catch {
            Write-Warning "Failed to revert .bashrc configuration: $($_.Exception.Message)"
        }
    } else {
        Write-Host "No .bashrc file found"
    }
}

# Load and validate configuration
$config = Get-Configuration
Validate-Configuration -config $config

# Show what packages are currently installed vs what we expect to find
Write-Host "=== Current System Status ===" -ForegroundColor Cyan
$installedApps = Get-InstalledPackages
if ($installedApps.Count -eq 0) {
    Write-Host "No packages are currently installed via Scoop." -ForegroundColor Yellow
} else {
    Write-Host "Currently installed packages: $($installedApps.Count)" -ForegroundColor Green
}

# Show what packages we expect to find based on config
$expectedPackages = @()
if($config.dependencies) {
    $expectedPackages += $config.dependencies | ForEach-Object { $_.name }
}
if($config.devDependencies) {
    $expectedPackages += $config.devDependencies | ForEach-Object { $_.name }
}

Write-Host "Packages configured in this dev-env-setup: $($expectedPackages.Count)" -ForegroundColor Cyan
Write-Host "Expected packages: $($expectedPackages -join ', ')" -ForegroundColor Gray
Write-Host ""
# Proceed with uninstall - only packages installed by this dev-env-setup will be removed
Write-Host "Proceeding with uninstall..." -ForegroundColor Green
Write-Host "Only packages installed by this dev-env-setup will be removed." -ForegroundColor Yellow
Write-Host "Packages installed independently will be preserved." -ForegroundColor Yellow
Write-Host ""

# Uninstall applications first
Write-Host "=== Uninstalling configured applications ==="

# Uninstall devDependencies
Write-Host "Uninstalling development dependencies..."
foreach($devDep in $config.devDependencies) {
    Uninstall-App -appName $devDep.name -description $devDep.description -Config $config
}

# Uninstall dependencies
Write-Host "Uninstalling dependencies..."
foreach($dep in $config.dependencies) {
    Uninstall-App -appName $dep.name -description $dep.description -Config $config
}

# Note: We do not uninstall Scoop itself as it may be used for other packages
Write-Host "=== Scoop Package Manager ==="
Write-Host "Scoop package manager is preserved as it may be used for other packages outside this dev-env-setup."

# Revert Git configuration (only what we set)
Revert-GitConfiguration -Config $config

# Revert SSH configuration (only what we set)
Revert-SSHConfiguration

# Revert Git Bash configuration (only what we set)
Revert-GitBashConfiguration

# Clean up buckets we added (only if no other packages depend on them)
Write-Host "=== Cleaning up Scoop buckets ==="
try {
    $bucketListOutput = scoop bucket list 2>$null
    [string[]] $currentBuckets = ($bucketListOutput | ForEach-Object { ($_ -split '\s+')[0] }) | Where-Object { $_ -ne "Name" -and $_ -ne "" }
    
    foreach($bucket in $config.buckets) {
        if($currentBuckets -and $currentBuckets.Contains($bucket)) {
            Write-Host "Checking if bucket '$bucket' can be safely removed..."
            
            # Check if any packages are installed from this bucket
            $bucketPackages = @()
            try {
                $bucketListOutput = scoop list 2>$null
                $lines = $bucketListOutput -split "`n"
                foreach($line in $lines) {
                    if($line -match "^\s*(\w+)\s+.*$bucket") {
                        $bucketPackages += $matches[1]
                    }
                }
            } catch {
                # If we can't determine packages, be conservative and don't remove bucket
                Write-Host "  -> Cannot determine packages in bucket '$bucket', keeping it"
                continue
            }
            
            if($bucketPackages.Count -eq 0) {
                Write-Host "  -> Removing bucket '$bucket' (no packages installed from it)"
                scoop bucket rm $bucket 2>$null
                if($LASTEXITCODE -eq 0) {
                    Write-Host "  -> Successfully removed bucket '$bucket'"
                } else {
                    Write-Host "  -> Failed to remove bucket '$bucket' (may be in use)"
                }
            } else {
                Write-Host "  -> Keeping bucket '$bucket' (packages still installed: $($bucketPackages -join ', '))"
            }
        } else {
            Write-Host "Bucket '$bucket' not found or already removed"
        }
    }
} catch {
    Write-Warning "Failed to clean up buckets: $($_.Exception.Message)"
}

# Note: We do not remove the Scoop directory as it may contain other packages
Write-Host "=== Scoop Directory ==="
Write-Host "Scoop directory is preserved as it may contain other packages installed outside this dev-env-setup."

Write-Host "=== Uninstall Complete ==="
Write-Host ""
Write-Host "Summary:"
Write-Host "- Removed only packages that were installed by this dev-env-setup"
Write-Host "- Preserved Scoop package manager and any other packages you installed independently"
Write-Host "- Reverted Git, SSH, and Git Bash configurations to their previous state"
Write-Host "- Cleaned up buckets only if no other packages depend on them"
Write-Host ""
Write-Host "Your system is now clean of this dev-env-setup while preserving your other tools."