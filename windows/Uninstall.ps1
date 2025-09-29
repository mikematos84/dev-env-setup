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

# Clean up Git configuration
Write-Host "=== Cleaning up Git configuration ==="
if((Test-CommandExists git) -eq $true){
    Write-Host "Resetting Git global configuration..."
    try {
        # Reset Git configuration to defaults
        git config --global --unset user.name 2>$null
        git config --global --unset user.email 2>$null
        git config --global --unset init.defaultBranch 2>$null
        git config --global --unset core.sshCommand 2>$null
        git config --global --unset push.autoSetupRemote 2>$null
        Write-Host "Git configuration reset successfully"
    } catch {
        Write-Warning "Failed to reset some Git configuration settings: $($_.Exception.Message)"
    }
} else {
    Write-Host "Git not found, skipping Git configuration cleanup"
}

# Clean up SSH configuration
Write-Host "=== Cleaning up SSH configuration ==="
$sshConfigPath = "$HOME\.ssh\config"
if(Test-Path $sshConfigPath){
    Write-Host "Removing SSH config file..."
    try {
        Remove-Item $sshConfigPath -Force
        Write-Host "SSH config file removed successfully"
    } catch {
        Write-Warning "Failed to remove SSH config file: $($_.Exception.Message)"
    }
} else {
    Write-Host "No SSH config file found"
}

# Clean up Git Bash configuration
Write-Host "=== Cleaning up Git Bash configuration ==="
$bashrcPath = "$HOME\.bashrc"
if(Test-Path $bashrcPath){
    Write-Host "Removing Git Bash SSH configuration from .bashrc..."
    try {
        $content = Get-Content $bashrcPath -Raw
        if($content -match "Configure Git Bash to use Windows SSH agent"){
            # Remove our SSH configuration block
            $newContent = $content -replace "(?s)# Configure Git Bash to use Windows SSH agent.*?fi\s*\n", ""
            if($newContent.Trim() -eq ""){
                # If file is empty after removal, delete it
                Remove-Item $bashrcPath -Force
                Write-Host ".bashrc file removed (was empty after cleanup)"
            } else {
                # Write back the cleaned content
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($bashrcPath, $newContent, $utf8NoBom)
                Write-Host "Git Bash SSH configuration removed from .bashrc"
            }
        } else {
            Write-Host "No Git Bash SSH configuration found in .bashrc"
        }
    } catch {
        Write-Warning "Failed to clean up .bashrc: $($_.Exception.Message)"
    }
} else {
    Write-Host "No .bashrc file found"
}

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