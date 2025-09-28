function Set-SSHAgentToAutomaticStartup {
  Write-Host "=== Configuring SSH Agent ===" 
  
  try {
    # Check if SSH Agent service exists (try different possible names)
    $sshAgentService = $null
    $possibleNames = @("ssh-agent", "OpenSSH Authentication Agent", "ssh-agent")
    
    foreach($serviceName in $possibleNames) {
      $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
      if($service) {
        $sshAgentService = $service
        Write-Host "Found SSH Agent service: $($service.DisplayName)"
        break
      }
    }
    
    if($null -eq $sshAgentService) {
      Write-Warning "SSH Agent service not found after installing git-with-openssh."
      Write-Host "This might be because:"
      Write-Host "1. The service needs a restart to be available"
      Write-Host "2. OpenSSH components need to be installed separately"
      Write-Host ""
      Write-Host "To install OpenSSH for Windows manually:"
      Write-Host "1. Run PowerShell as Administrator"
      Write-Host "2. Run: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
      Write-Host "3. Run: Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
      Write-Host "4. Restart this script after installation"
      return
    }
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    $serviceName = $sshAgentService.Name
    
    if($isAdmin) {
      Write-Host "Setting SSH Agent to start automatically..."
      Set-Service -Name $serviceName -StartupType Automatic -PassThru
      Write-Host "Starting SSH Agent service..."
      Start-Service -Name $serviceName
      Write-Host "SSH Agent configured successfully."
    } else {
      Write-Host "Attempting to configure SSH Agent with elevated privileges..."
      if((Test-CommandExists sudo) -eq $true) {
        sudo Set-Service -Name $serviceName -StartupType Automatic -PassThru
        sudo Start-Service -Name $serviceName
        Write-Host "SSH Agent configured successfully."
      } else {
        Write-Warning "Administrator privileges required to configure SSH Agent."
        Write-Host "Please run this script as administrator or install sudo first."
      }
    }
  } catch {
    Write-Error "Failed to configure SSH Agent: $($_.Exception.Message)"
  }
}