function Write-SSHConfig {
  Write-Host "=== Generating SSH Config ==="
  
  $content = @"
Host *
  AddKeysToAgent yes
  IdentitiesOnly yes

Host github.com
  Hostname github.com
  User git
"@

  # Ensure .ssh directory exists
  if(!(Test-Path -Path $HOME\.ssh)){
    Write-Host "Creating .ssh directory..."
    New-Item -Path $HOME -Name .ssh -ItemType Directory -Force | Out-Null
  }

  # Find SSH public keys
  $keys = Get-ChildItem -Path $HOME\.ssh -Filter *.pub -ErrorAction SilentlyContinue
  
  if($keys) {
    Write-Host "Found $($keys.Count) SSH key(s), adding to config..."
    foreach($key in $keys){
        $keyName = $key.Name.replace('.pub','')
        $content += "`n  IdentityFile ~/.ssh/$keyName"
        Write-Host "  Added key: $keyName"
    }
  } else {
    Write-Warning "No SSH public keys found in $HOME\.ssh"
    Write-Host "To generate SSH keys, run: ssh-keygen -t ed25519 -C 'your_email@example.com'"
  }

  # Write the config file using UTF8 without BOM
  try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText("$HOME\.ssh\config", $content, $utf8NoBom)
    Write-Host "SSH config written to $HOME\.ssh\config"
  } catch {
    Write-Error "Failed to write SSH config: $($_.Exception.Message)"
  }
}