function Validate-Configuration {
    param(
        [object]$config
    )
    
    $errors = @()
    $warnings = @()
    
    # Validate required sections
    if(-not $config.buckets) {
        $errors += "Missing 'buckets' section in configuration"
    } elseif($config.buckets -isnot [array] -and $config.buckets.GetType().Name -notlike "*List*") {
        $errors += "'buckets' must be an array"
    }
    
    if(-not $config.packages) {
        $warnings += "Missing 'packages' section in configuration - no packages will be installed"
    } elseif($config.packages -isnot [array] -and $config.packages.GetType().Name -notlike "*List*") {
        $errors += "'packages' must be an array"
    }
    
    if(-not $config.system) {
        $warnings += "Missing 'system' section in configuration - using defaults"
    }
    
    # Validate packages structure
    if($config.packages) {
        foreach($package in $config.packages) {
            if(-not $package -or $package -eq "") {
                $errors += "Empty package name found in packages array"
            }
        }
    }
    
    # Validate system configuration
    if($config.system) {
        if($config.system.sshAgent -and $config.system.sshAgent.enabled -eq $null) {
            $warnings += "SSH Agent 'enabled' property not specified - defaulting to true"
        }
        if($config.system.sshAgent -and $config.system.sshAgent.autoStart -eq $null) {
            $warnings += "SSH Agent 'autoStart' property not specified - defaulting to true"
        }
    }
    
    # Display warnings
    if($warnings.Count -gt 0) {
        Write-Host "Configuration warnings:" -ForegroundColor Yellow
        foreach($warning in $warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    
    # Display errors and exit if any
    if($errors.Count -gt 0) {
        Write-Host "Configuration errors:" -ForegroundColor Red
        foreach($error in $errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
        Write-Error "Configuration validation failed. Please fix the errors above."
        exit 1
    }
    
    Write-Host "Configuration validation passed" -ForegroundColor Green
}

