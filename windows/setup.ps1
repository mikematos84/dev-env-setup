$config = (Get-Content "$PSScriptRoot\\apps.json" | ConvertFrom-Json)

Write-Output "
  === Scoop ===
"
if(Get-Command "scoop" -ErrorAction SilentlyContinue){
  Write-Output "Previous scoop installation found";
  if((Get-Command "git" -ErrorAction SilentlyContinue) -eq $null){
    Write-Output "Missing git dependency required for update"
    scoop install git-with-openssh
  }
}else{
  Write-Output "Installing scoop."
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
  irm get.scoop.sh | iex

  # Install Git
  Write-Output "Installing git"
  scoop install git-with-openssh
}
scoop update

# Install extras bucket
Write-Output "
  === Buckets ===
"
scoop bucket add extras

# Install apps
Write-Output "
  === Core Apps ===
"
$list=(Invoke-Expression "scoop list").Name
foreach($app in $config.core){
  if($list.Contains($app)){
    Invoke-Expression "scoop update $app";
  }else{
    Invoke-Expression "scoop install $app"
  }
}

# Setup node environment
Write-Output "
  === NVM (Node Version Manager) ===
  nvm version $(nvm version)
"
foreach($version in $config.nvm.versions){
  Invoke-Expression "nvm install $version"
}
sudo nvm use $config.default
node -v
npm -v

Write-Host "
  Environment setup complete!

  For more information on scoop and a list of apps available, visit https://scoop.sh
"