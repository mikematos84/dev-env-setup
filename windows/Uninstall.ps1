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

if(Test-Path $HOME\scoop){
	Write-Host "Removing Scoop directory..."
	Remove-Item $HOME\scoop -Force -Recurse
	if($?) {
		Write-Host "Scoop directory removed successfully."
	} else {
		Write-Warning "Failed to remove Scoop directory. You may need to remove it manually."
	}
} else {
	Write-Host "No Scoop directory found at $HOME\scoop"
}

Write-Host "=== Uninstall Complete ==="