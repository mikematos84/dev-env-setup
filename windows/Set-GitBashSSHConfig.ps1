function Set-GitBashSSHConfig {
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