param(
  [Parameter(HelpMessage="Forces clean install")]
  [switch]$clean=$false
)

# Import Modules
. .\windows\Invoke-InstallUpdateApp.ps1

# Get apps config
$config = (Get-Content "$PSScriptRoot\\apps.json" | ConvertFrom-Json)

# Clean install. Remove scoop if found
if($clean -eq $true){
  if((Get-Command "scoop" -ErrorAction SilentlyContinue)){
    scoop uninstall scoop
  }
}

Write-Host "
  === Scoop ===
"
# Install scoop if not found
if($null -eq (Get-Command "scoop" -ErrorAction SilentlyContinue)){
  Write-Host "Installing scoop."
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
  Invoke-RestMethod get.scoop.sh | Invoke-Expression
}

# Install git-with-openssh dependency if not found
# Needed to manage scoop and its buckets
if($null -eq (Get-Command "git" -ErrorAction SilentlyContinue)){
  Write-Host "Missing git dependency required for update"
  foreach($dep in $config.dependencies){
    # Assume entries will be an array of strings be default
    $app = $dep;
    $props = $null;

    # Check to see if entry is an array and set $app to the first
    # index as that pattern should assume it is the name.
    if($dep -is [System.Array]){
      $app = $dep[0];
      $props = $dep[1];
    }

    if(($null -ne $props) -and ($props.install -eq $false)){
      # Don't install due to props.install override being false
    }else{
      Invoke-InstallUpdateApp -app $app;
    }
  }
}


# Force update to latest if not already
scoop update

# Install extras bucket
Write-Host "
  === Buckets ===
"
scoop bucket add extras

# Install apps
Write-Host "
  === Apps ===
"
$list=(Invoke-Expression "scoop list").Name
foreach($entry in $config.devDependencies){
  $app = $entry;
  $props = $null;

  if($entry -is [System.Array]){
    $app = $entry[0];
    $props = $entry[1];
  }

  if(($null -eq $props) -or ($props.install -eq $true)){
    # install app
    Invoke-InstallUpdateApp -app $app;
  }

  if($props.run){
    Invoke-Expression "$($props.run)"
  }
}

if((Get-Command "nvm" -ErrorAction SilentlyContinue)){
  # Setup node environment
  Write-Host "
    === NVM (Node Version Manager) ===
    nvm version $(nvm version)
  "
  $nvm = $config.devDependencies.where{$_ -match 'nvm'}
  foreach($version in $nvm.versions){
    Invoke-Expression "nvm install $version"
  }
  sudo nvm use $nvm.default
  node -v
  npm -v
}

if((Get-Command "yarn" -ErrorAction SilentlyContinue)){
  # Setup yarn
  Write-Host "
    === Configure Yarn ===
  "  
  Invoke-Expression "yarn set version berry"
  yarn -v
}

if((Get-Service "ssh-agent" -ErrorAction SilentlyContinue)){
  # Setup yarn
  Write-Host "
    === Configure SSH (for Git Bash) ===
  " 
  
  Write-Host "Setting ssh-agent StartupType to Automatic"
  Invoke-Expression "sudo Set-Service -Name ssh-agent -StartupType Automatic"
  
  Write-Host "Setting ssh-agent Status to Running"
  Invoke-Expression "sudo Set-Service -Name ssh-agent -Status Running"
  
  Write-Host "
    - adding empty .bash_profile
    - adding .bashrc to automatically start ssh-agent on opening a new bash terminal
    - adding .ssh/config for github.com
  "
  Copy-Item -Path ".\windows\home\*" -Destination "$HOME" -Recurse -Force
}

Write-Host "
  Environment setup complete!

  For more information on scoop and a list of apps available, visit https://scoop.sh
"