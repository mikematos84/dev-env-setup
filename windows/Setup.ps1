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
    $bootstrapConfigPath = Join-Path (Split-Path $scriptPath -Parent) "bootstrap.yaml"
    
    if (Test-Path $bootstrapConfigPath) {
        try {
            # Ensure powershell-yaml module is available
            if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
                Write-Host "Installing powershell-yaml module..."
                Install-Module -Name powershell-yaml -Force -Scope CurrentUser -AllowClobber
            }
            
            Import-Module powershell-yaml -Force
            
            # Load bootstrap config
            $bootstrapConfig = Get-Content $bootstrapConfigPath -Raw | ConvertFrom-Yaml
            Write-Host "Bootstrap configuration loaded successfully from $bootstrapConfigPath"
            
            # Create merged config similar to OSX approach
            $mergedConfig = @{
                buckets = @("extras")  # Default bucket
                packages = @()
                system = @{}
            }
            
            # Add global packages
            if ($bootstrapConfig.packages) {
                foreach ($package in $bootstrapConfig.packages) {
                    $mergedConfig.packages += $package
                }
            }
            
            # Add Windows-specific packages with smart merging
            if ($bootstrapConfig.platforms.windows.packages) {
                foreach ($package in $bootstrapConfig.platforms.windows.packages) {
                    # Check if this package already exists (by name)
                    $existingPackageIndex = -1
                    for ($i = 0; $i -lt $mergedConfig.packages.Count; $i++) {
                        $existingPackage = $mergedConfig.packages[$i]
                        $existingPackageName = if ($existingPackage -is [string]) { $existingPackage } else { $existingPackage.name }
                        if ($existingPackageName -eq $package.name) {
                            $existingPackageIndex = $i
                            break
                        }
                    }
                    
                    if ($existingPackageIndex -ge 0) {
                        # Merge with existing package
                        $existingPackage = $mergedConfig.packages[$existingPackageIndex]
                        if ($existingPackage -is [string]) {
                            # Convert string to object and merge
                            $mergedPackage = @{
                                name = $existingPackage
                                run = $package.run
                                install = $package.install
                            }
                        } else {
                            # Merge object properties
                            $mergedPackage = $existingPackage.PSObject.Copy()
                            if ($package.run) {
                                # Append platform-specific run commands
                                $mergedPackage.run = $existingPackage.run + "`n" + $package.run
                            }
                            if ($package.install -ne $null) {
                                $mergedPackage.install = $package.install
                            }
                        }
                        $mergedConfig.packages[$existingPackageIndex] = $mergedPackage
                    } else {
                        # Add new package
                        $mergedConfig.packages += $package
                    }
                }
            }
            
            # Add Windows-specific system configuration
            if ($bootstrapConfig.platforms.windows.sshAgent) {
                $mergedConfig.system.sshAgent = $bootstrapConfig.platforms.windows.sshAgent
            }
            
            
            Write-Host "Merged configuration created successfully"
            return $mergedConfig
        } catch {
            Write-Error "Failed to parse bootstrap configuration file: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Error "Bootstrap configuration file not found: $bootstrapConfigPath"
        Write-Host "Please ensure bootstrap.yaml exists in the project root."
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
  	
# Install packages
Write-Host "Installing packages..."
if ($config.packages) {
    foreach($package in $config.packages) {
        # Handle both string packages and object packages
        if ($package -is [string]) {
            $packageName = $package
            $runCommands = $null
            $shouldInstall = $true
        } else {
            $packageName = $package.name
            $runCommands = $package.run
            $shouldInstall = $package.install -ne $false  # Default to true unless explicitly false
        }
        
        if (-not $shouldInstall) {
            Write-Host "Skipping installation of $packageName (install: false)"
        } else {
            Write-Host "Installing $packageName..."
            scoop install $packageName
            if($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to install package: $packageName"
            } else {
                Write-Host "Successfully installed $packageName"
            }
        }
        
        # Execute run commands if specified (regardless of installation)
        if ($runCommands) {
            Write-Host "Running post-install commands for $packageName..."
            try {
                # Split multi-line commands and execute each
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
            } catch {
                Write-Warning "Error running post-install commands for $packageName`: $($_.Exception.Message)"
            }
        }
    }
} else {
    Write-Host "No packages to install"
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

# Git configuration is now handled by package run commands

Write-Host "=== Installation Complete ==="
Write-Host "You may need to restart your terminal or run 'refreshenv' to use the newly installed tools."
