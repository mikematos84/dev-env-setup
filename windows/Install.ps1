# https://scoop.sh/

# Import Modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\Test-CommandExists.ps1"
. "$scriptPath\Set-SSHAgentToAutomaticStartup.ps1"
. "$scriptPath\Write-SSHConfig.ps1"
. "$scriptPath\Set-GitConfiguration.ps1"
. "$scriptPath\Validate-Configuration.ps1"

Write-Host "=== Windows Developer Environment Setup ==="

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

function Install-App {
    param(
        [string]$appName,
        [string]$description,
        [bool]$required = $false,
        [string]$postInstall = $null
    )
    
    Write-Host "Installing $appName ($description)..."
    scoop install $appName
    if($LASTEXITCODE -ne 0) {
        if($required) {
            Write-Error "Failed to install required app: $appName"
            exit 1
        } else {
            Write-Warning "Failed to install optional app: $appName"
        }
    } else {
        Write-Host "Successfully installed $appName"
        
        # Execute post-install commands if specified
        if($postInstall) {
            Write-Host "Running post-install commands for $appName..."
            try {
                Invoke-Expression $postInstall
                if($LASTEXITCODE -ne 0) {
                    Write-Warning "Post-install commands for $appName failed"
                } else {
                    Write-Host "Post-install commands for $appName completed successfully"
                }
            } catch {
                Write-Warning "Error running post-install commands for $appName`: $($_.Exception.Message)"
            }
        }
    }
}

# Load and validate configuration
$config = Get-Configuration
Validate-Configuration -config $config

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if((Test-CommandExists scoop) -eq $false){
  	Write-Host "Installing Scoop package manager..."
  	Write-Host "This will set execution policy to RemoteSigned for current user."
  	$response = Read-Host "Continue? (y/N)"
  	if($response -eq 'y' -or $response -eq 'Y') {
  		Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  		Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  		if($LASTEXITCODE -ne 0) {
  			Write-Error "Failed to install Scoop. Please run as administrator or check your internet connection."
  			exit 1
  		}
  	} else {
  		Write-Host "Scoop installation cancelled."
  		exit 0
  	}
}
  	
# Install dependencies
Write-Host "Installing dependencies..."
foreach($dep in $config.dependencies) {
    if($dep.required) {
        if((Test-CommandExists git) -eq $false -and $dep.name -eq "git-with-openssh") {
            Install-App -appName $dep.name -description $dep.description -required $dep.required
        } elseif($dep.name -ne "git-with-openssh") {
            Install-App -appName $dep.name -description $dep.description -required $dep.required
        }
    } else {
        Write-Host "Skipping optional dependency: $($dep.name) ($($dep.description))"
    }
}

Write-Host "Updating Scoop..."
scoop update scoop
if($LASTEXITCODE -ne 0) {
	Write-Warning "Failed to update Scoop. Continuing with installation..."
}

# Add Scoop buckets (must be done before installing apps that depend on them)
Write-Host "Adding Scoop buckets..."
try {
	$bucketListOutput = scoop bucket list 2>$null
	[string[]] $addedBuckets = ($bucketListOutput | ForEach-Object { ($_ -split '\s+')[0] }) | Where-Object { $_ -ne "Name" -and $_ -ne "" }
} catch {
	$addedBuckets = @()
}

foreach($bucket in $config.buckets){
	if(($null -eq $addedBuckets) -or (!$addedBuckets.Contains($bucket))){
		Write-Host "Adding bucket: $bucket"
		scoop bucket add $bucket
		if($LASTEXITCODE -ne 0) {
			Write-Warning "Failed to add bucket: $bucket"
		}
  	} else {
  		Write-Host "Bucket $bucket already exists"
  	}
}

# Install devDependencies
Write-Host "Installing development dependencies..."
foreach($devDep in $config.devDependencies) {
    if($devDep.required) {
        Install-App -appName $devDep.name -description $devDep.description -required $devDep.required -postInstall $devDep.postInstall
    } else {
        Write-Host "Skipping optional devDependency: $($devDep.name) ($($devDep.description))"
    }
}

# Configure system settings based on configuration
if($config.system.sshAgent.enabled) {
    $sshAgentService = Get-Service -Name "ssh-agent" -ErrorAction SilentlyContinue
    if($sshAgentService) {
        Write-Host "Configuring SSH Agent..."
        if($config.system.sshAgent.autoStart) {
            Set-SSHAgentToAutomaticStartup
        }
        Write-SSHConfig
    } else {
        Write-Warning "SSH Agent service not found. SSH configuration skipped."
    }
}

# Configure Git settings from config
if($config.system.git -and (Test-CommandExists git) -eq $true){
    Set-GitConfiguration -Config $config
}

Write-Host "=== Installation Complete ==="
Write-Host "You may need to restart your terminal or run 'refreshenv' to use the newly installed tools."
