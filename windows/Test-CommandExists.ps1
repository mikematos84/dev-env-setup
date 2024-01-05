function Test-CommandExists {
	Param($command);
	$oldPreference = $ErrorActionPreference
 	$ErrorActionPreference = 'stop'
	try {
		if(Get-Command $command){
			return $true;
		}
	}catch{
		return $false;
	}finally{
		$ErrorActionPreference=$oldPreference
	}
}