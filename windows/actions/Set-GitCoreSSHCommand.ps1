function Set-GitCoreSSHCommand {
  Write-Host "=== Configure Git to work with SSH ==="
	Invoke-Expression "git config --global core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe"
}