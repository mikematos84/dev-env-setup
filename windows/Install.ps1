# https://scoop.sh/

# Import Modules
. ..\windows\Test-CommandExists.ps1
. ..\windows\Set-SSHAgentToAutomaticStartup.ps1
. ..\windows\Write-SSHConfig.ps1
. ..\windows\Set-GitCoreSSHCommand.ps1

Write-Host "=== Windows Developer Environment Setup ==="

if((Test-CommandExists scoop) -eq $false){
  	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  	Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}
  	
if((Test-CommandExists git) -eq $false){ scoop install git-with-openssh }

scoop update scoop

if((Test-CommandExists sudo) -eq $false){ scoop install sudo }

if((Test-CommandExists nvm) -eq $false) {
	scoop install nvm
	nvm install lts
	sudo nvm use lts
}

if((Test-CommandExists ssh-agent) -eq $true){
	Set-SSHAgentToAutomaticStartup
	Write-SSHConfig
}

if((Test-CommandExists git) -eq $true){
	Set-GitCoreSSHCommand
}

$buckets = @("extras");
[string[]] $addedBuckets=(Invoke-Expression "scoop bucket list").Name

foreach($bucket in $buckets){
	if(($null -ne $addedBuckets) -and (!$addedBuckets.Contains($bucket))){
		Invoke-Expression "scoop bucket add $($bucket)";
  	}
}

$apps = @("mkcert","yarn","vscode")
[string[]] $installedApps=(Invoke-Expression "scoop list").Name

foreach($app in $apps){
	$method = "install"
	if(($null -ne $installedApps) -and ($installedApps.Contains($app))){
   		$method = "update"
  	}
	Invoke-Expression "scoop $($method) $($app)";
}
