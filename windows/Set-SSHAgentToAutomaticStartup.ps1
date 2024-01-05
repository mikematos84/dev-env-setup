function Set-SSHAgentToAutomaticStartup {
  Write-Host "=== Configure SSH ===" 
	sudo Get-Service ssh-agent | Set-Service -StartupType Automatic -PassThru 
  Start-Service ssh-agent
}