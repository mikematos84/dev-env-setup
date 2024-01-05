function Write-SSHConfig {
  $content = @"
Host *
  AddKeysToAgent yes

Host github.com
  Hostname github.com
"@

  if(!(Test-Path -Path $HOME\.ssh)){
    New-Item -Path $HOME -Name .ssh -ItemType Directory
  }

  $keys = (Get-ChildItem -Path $HOME\.ssh -Filter *.pub)
  foreach($key in $keys){
      $content += "`n  IdentityFile ~/.ssh/$($key.Name.replace('.pub',''))"
  }

  Write-Host "=== Generate SSH Config ==="
  $content | Out-File -FilePath $HOME\.ssh\config -Encoding UTF8 -Force
}