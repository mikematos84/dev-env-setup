function Set-GitConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    
    Write-Host "=== Configuring Git Settings ==="
    
    if (-not (Test-CommandExists git)) {
        Write-Warning "Git is not installed or not in PATH. Skipping Git configuration."
        return
    }
    
    try {
        # Configure global Git settings from config
        if ($Config.system.git.config.global) {
            $globalConfig = $Config.system.git.config.global
            
            # Set user information
            if ($globalConfig.user) {
                if ($globalConfig.user.name) {
                    Write-Host "Setting Git user name: $($globalConfig.user.name)"
                    git config --global user.name $globalConfig.user.name
                }
                if ($globalConfig.user.email) {
                    Write-Host "Setting Git user email: $($globalConfig.user.email)"
                    git config --global user.email $globalConfig.user.email
                }
            }
            
            # Set init settings
            if ($globalConfig.init) {
                if ($globalConfig.init.defaultBranch) {
                    Write-Host "Setting default branch: $($globalConfig.init.defaultBranch)"
                    git config --global init.defaultBranch $globalConfig.init.defaultBranch
                }
            }
            
            # Set core settings
            if ($globalConfig.core) {
                if ($globalConfig.core.sshCommand) {
                    Write-Host "Setting SSH command: $($globalConfig.core.sshCommand)"
                    git config --global core.sshCommand $globalConfig.core.sshCommand
                }
            }
            
            # Set push settings
            if ($globalConfig.push) {
                if ($globalConfig.push.autoSetupRemote) {
                    Write-Host "Setting push auto setup remote: $($globalConfig.push.autoSetupRemote)"
                    git config --global push.autoSetupRemote $globalConfig.push.autoSetupRemote
                }
            }
            
            Write-Host "Git global configuration completed successfully"
        } else {
            Write-Warning "No global Git configuration found in config.json"
        }
        
        # Configure SSH-related settings if configureSSH is enabled
        if ($Config.system.git.configureSSH) {
            Write-Host "Configuring Git SSH integration..."
            
            # The SSH command should already be set above, but we'll ensure it's set
            if ($Config.system.git.config.global.core.sshCommand) {
                Write-Host "Ensuring SSH command is configured: $($Config.system.git.config.global.core.sshCommand)"
                git config --global core.sshCommand $Config.system.git.config.global.core.sshCommand
            }
            
            # Configure Git Bash SSH integration
            Set-GitBashSSHConfig -SshCommand $Config.system.git.config.global.core.sshCommand
        }
        
    } catch {
        Write-Error "Failed to configure Git: $($_.Exception.Message)"
    }
}

function Set-GitBashSSHConfig {
    param(
        [string]$SshCommand = "C:/Windows/System32/OpenSSH/ssh.exe"
    )
    
    Write-Host "=== Configuring Git Bash SSH Integration ==="
    
    $bashrcPath = "$HOME\.bashrc"
    $sshConfig = @"
# Configure Git Bash to use Windows SSH agent
# Add Windows OpenSSH to PATH
export PATH="/c/Windows/System32/OpenSSH:`$PATH"

# Check if we can access the SSH agent (silent check)
if ! ssh-add -l >/dev/null 2>&1; then
    echo "SSH agent not accessible. This is normal - Git will use the configured SSH client."
    echo "Git is configured to use: `$(git config --global core.sshCommand)"
fi
"@

    try {
        # Check if .bashrc exists
        if (Test-Path $bashrcPath) {
            Write-Host "Found existing .bashrc file"
            
            # Read current content
            $currentContent = Get-Content $bashrcPath -Raw
            
            # Check if our SSH config already exists
            if ($currentContent -match "Configure Git Bash to use Windows SSH agent") {
                Write-Host "SSH configuration already exists in .bashrc"
                return
            }
            
            # Prepend our config to existing content
            Write-Host "Adding SSH configuration to existing .bashrc"
            $newContent = $sshConfig + "`n`n" + $currentContent
            
            # Write using UTF8 without BOM
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($bashrcPath, $newContent, $utf8NoBom)
            Write-Host "SSH configuration added to .bashrc"
        } else {
            Write-Host "Creating new .bashrc file with SSH configuration"
            
            # Write using UTF8 without BOM
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($bashrcPath, $sshConfig, $utf8NoBom)
            Write-Host ".bashrc created successfully"
        }
        
        Write-Host "Git Bash SSH configuration completed"
    } catch {
        Write-Error "Failed to configure Git Bash SSH: $($_.Exception.Message)"
    }
}
