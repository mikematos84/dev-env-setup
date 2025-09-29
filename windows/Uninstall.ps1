# https://github.com/ScoopInstaller/Scoop/wiki/Uninstalling-Scoop

# Import Modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\Test-CommandExists.ps1"
. "$scriptPath\Validate-Configuration.ps1"

Write-Host "=== Uninstall Windows Developer Environment Setup ==="

# Load Configuration
function Get-Configuration {
    $configPath = Join-Path $scriptPath "config.json"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            Write-Host "Configuration loaded successfully from $configPath"
            return $config
        } catch {
            Write-Error "Failed to parse configuration file: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Error "Configuration file not found: $configPath"
        Write-Host "Please ensure config.json exists in the windows directory."
        exit 1
    }
}

function Uninstall-App {
    param(
        [string]$appName,
        [string]$description
    )
    
    try {
        $scoopListOutput = scoop list 2>$null
        [string[]] $installedApps = ($scoopListOutput | ForEach-Object { ($_ -split '\s+')[0] }) | Where-Object { $_ -ne "Name" -and $_ -ne "" }
    } catch {
        $installedApps = @()
    }
    
    if(($null -ne $installedApps) -and ($installedApps.Contains($appName))){
        Write-Host "Uninstalling $appName ($description)..."
        scoop uninstall $appName
        if($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to uninstall $appName"
        } else {
            Write-Host "Successfully uninstalled $appName"
        }
    } else {
        Write-Host "$appName ($description) is not installed"
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

# Uninstall applications first
Write-Host "=== Uninstalling configured applications ==="

# Uninstall devDependencies
Write-Host "Uninstalling development dependencies..."
foreach($devDep in $config.devDependencies) {
    Uninstall-App -appName $devDep.name -description $devDep.description
}

# Uninstall dependencies
Write-Host "Uninstalling dependencies..."
foreach($dep in $config.dependencies) {
    Uninstall-App -appName $dep.name -description $dep.description
}

# Ask about removing Scoop itself
if((Test-CommandExists scoop) -eq $true){
	Write-Host "=== Uninstalling Scoop ==="
	$response = Read-Host "This will remove Scoop package manager. Continue? (y/N)"
	if($response -eq 'y' -or $response -eq 'Y') {
		scoop uninstall scoop
		if($LASTEXITCODE -ne 0) {
			Write-Warning "Failed to uninstall Scoop via scoop command. Attempting manual cleanup..."
		}
	} else {
		Write-Host "Scoop uninstall cancelled."
	}
} else {
	Write-Host "Scoop not found. Checking for manual cleanup..."
}

# Revert Git configuration (only what we set)
Revert-GitConfiguration -Config $config

# Revert SSH configuration (only what we set)
Revert-SSHConfiguration

# Revert Git Bash configuration (only what we set)
Revert-GitBashConfiguration

# Clean up Scoop directory
if(Test-Path $HOME\scoop){
	Write-Host "=== Removing Scoop directory ==="
	Write-Host "Attempting to remove Scoop directory and all contents..."
	
	try {
		# First, try to remove with more aggressive parameters
		Remove-Item $HOME\scoop -Force -Recurse -ErrorAction Stop
		Write-Host "Scoop directory removed successfully."
	} catch {
		Write-Warning "Failed to remove Scoop directory: $($_.Exception.Message)"
		Write-Host "Attempting alternative cleanup method..."
		
		try {
			# Try removing individual files and folders
			Get-ChildItem $HOME\scoop -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
			Remove-Item $HOME\scoop -Force -ErrorAction Stop
			Write-Host "Scoop directory removed using alternative method."
		} catch {
			Write-Warning "Failed to remove Scoop directory completely."
			Write-Host "Some files may be in use. You may need to:"
			Write-Host "1. Close all terminal windows and PowerShell sessions"
			Write-Host "2. Restart your computer"
			Write-Host "3. Manually delete the directory: $HOME\scoop"
		}
	}
} else {
	Write-Host "No Scoop directory found at $HOME\scoop"
}

Write-Host "=== Uninstall Complete ==="