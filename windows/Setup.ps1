# https://scoop.sh/

# Handle command line parameters
param(
    [switch]$ConfigureSSHAgent
)

# Check if running as administrator (for optional admin-only features)
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to request admin privileges for specific operations
function Request-AdminForSSHAgent {
    if (-not (Test-Administrator)) {
        Write-Host "Restarting with elevated privileges for SSH Agent configuration..." -ForegroundColor Yellow
        
        # Get the current script path and arguments
        $scriptPath = $MyInvocation.MyCommand.Path
        $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" -ConfigureSSHAgent"
        
        # Start a new PowerShell process with elevated privileges
        try {
            Start-Process PowerShell -Verb RunAs -ArgumentList $arguments -Wait
            return $true
        } catch {
            Write-Error "Failed to elevate privileges for SSH Agent configuration."
            Write-Host "You can configure SSH Agent manually later by running this script as administrator." -ForegroundColor Yellow
            return $false
        }
    }
    return $true
}

# Import Modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\actions\Test-CommandExists.ps1"
. "$scriptPath\actions\Set-SSHAgentToAutomaticStartup.ps1"
. "$scriptPath\actions\Write-SSHConfig.ps1"
. "$scriptPath\actions\Set-GitConfiguration.ps1"
. "$scriptPath\actions\Validate-Configuration.ps1"

Write-Host "=== Windows Developer Environment Setup ==="

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

# If ConfigureSSHAgent parameter is passed, only configure SSH Agent and exit
if($ConfigureSSHAgent) {
    Write-Host "Configuring SSH Agent only..." -ForegroundColor Cyan
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
    Write-Host "SSH Agent configuration complete." -ForegroundColor Green
    exit 0
}

if((Test-CommandExists scoop) -eq $false){
  	Write-Host "Installing Scoop package manager..."
  	Write-Host "Setting execution policy to RemoteSigned for current user..."
  	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  	Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  	if($LASTEXITCODE -ne 0) {
  		Write-Error "Failed to install Scoop. Please run as administrator or check your internet connection."
  		exit 1
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
            # Try to configure SSH Agent, auto-elevate if needed
            if(Test-Administrator) {
                Set-SSHAgentToAutomaticStartup
            } else {
                Write-Host "SSH Agent configuration requires administrator privileges. Auto-elevating..." -ForegroundColor Yellow
                Request-AdminForSSHAgent
            }
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
