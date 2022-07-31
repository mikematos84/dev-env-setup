function Invoke-InstallUpdateApp {
  param(
    [Parameter(Mandatory, HelpMessage="App to install")]
    [string] $app,
    [Parameter(Mandatory = $false, HelpMessage="List of installed apps")]
    [string[]] $list=(Invoke-Expression "scoop list").Name
  )

  $method = "install";

  # If $app exists in list, update it, else install it
  if(($null -ne $list) -and ($list.Contains($app))){
    $method = "update"
  }

  Invoke-Expression "scoop $($method) $($app)";
}