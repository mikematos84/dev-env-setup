param(
  [Parameter(HelpMessage="Forces clean install")]
  [switch]$clean=$false
)

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
if((Get-Command "scoop" -ErrorAction SilentlyContinue) -eq $null){
  Write-Host "Installing scoop."
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
  irm get.scoop.sh | iex
}

# Install git-with-openssh dependency if not found
# Needed to manage scoop and its buckets
if((Get-Command "git" -ErrorAction SilentlyContinue) -eq $null){
  Write-Host "Missing git dependency required for update"
  scoop install git-with-openssh sudo
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
foreach($category in $config.apps.PSObject.Properties){
  Write-Host "--- $($category.Name)---"
  foreach($app in $config.apps.PSObject.Properties[$category.Name].Value){
    if($app.install -eq $true){
      if($list.Contains($app.Name)){
        Invoke-Expression "scoop update $($app.Name)";
      }else{
        Invoke-Expression "scoop install $($app.Name)"
      }
    }else{
      Write-Host "Skipping install of $($app.Name)"
    }
  }
}

if((Get-Command "nvm" -ErrorAction SilentlyContinue)){
  # Setup node environment
  Write-Host "
    === NVM (Node Version Manager) ===
    nvm version $(nvm version)
  "
  foreach($version in $config.nvm.versions){
    Invoke-Expression "nvm install $version"
  }
  sudo nvm use $config.nvm.default
  node -v
  npm -v
}

Write-Host "
  Environment setup complete!

  For more information on scoop and a list of apps available, visit https://scoop.sh
"