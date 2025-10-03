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
    
    if(-not $config.dependencies) {
        $errors += "Missing 'dependencies' section in configuration"
    } elseif($config.dependencies -isnot [array] -and $config.dependencies.GetType().Name -notlike "*List*") {
        $errors += "'dependencies' must be an array"
    }
    
    if(-not $config.devDependencies) {
        $errors += "Missing 'devDependencies' section in configuration"
    } elseif($config.devDependencies -isnot [array] -and $config.devDependencies.GetType().Name -notlike "*List*") {
        $errors += "'devDependencies' must be an array"
    }
    
    if(-not $config.system) {
        $warnings += "Missing 'system' section in configuration - using defaults"
    }
    
    # Validate dependencies structure
    if($config.dependencies) {
        foreach($dep in $config.dependencies) {
            if(-not $dep.name) {
                $errors += "Dependency missing 'name' property"
            }
            if(-not $dep.description) {
                $warnings += "Dependency '$($dep.name)' missing 'description' property"
            }
            if($dep.required -eq $null) {
                $warnings += "Dependency '$($dep.name)' missing 'required' property - defaulting to false"
            }
        }
    }
    
    # Validate devDependencies structure
    if($config.devDependencies) {
        foreach($devDep in $config.devDependencies) {
            if(-not $devDep.name) {
                $errors += "DevDependency missing 'name' property"
            }
            if(-not $devDep.description) {
                $warnings += "DevDependency '$($devDep.name)' missing 'description' property"
            }
            if($devDep.required -eq $null) {
                $warnings += "DevDependency '$($devDep.name)' missing 'required' property - defaulting to false"
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
        if($config.system.git -and $config.system.git.configureSSH -eq $null) {
            $warnings += "Git 'configureSSH' property not specified - defaulting to true"
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

