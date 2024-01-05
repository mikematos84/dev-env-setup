# https://github.com/ScoopInstaller/Scoop/wiki/Uninstalling-Scoop

# Import Modules
. ..\windows\Test-CommandExists.ps1

Write-Host "=== Uninstall Windows Developer Environment Setup ==="

if((Test-CommandExists scoop) -eq $true){
	Write-Host "=== Uninstalling Scoop (and all install apps) ==="
  	scoop uninstall scoop
}

if(Test-Path $HOME\scoop){
	Remove-Item .\scoop -Force -Recurse
}