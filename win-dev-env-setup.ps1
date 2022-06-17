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
Write-Output "Installing buckets"
scoop bucket add extras

# Install apps
Write-Output "Installing apps";
scoop install 7zip curl mkcert nvm sudo yarn vscode

# Setup node environment
Write-Output "nvm version $(nvm version)"
Write-Output "Installing node lts"
nvm install lts
sudo nvm use lts
node -v
npm -v

Write-Output "Environment setup complete!"