param(
	$IsVerbose = $false
)

function GetScriptPath
{
	$scriptFolder = (Get-Variable 'PSScriptRoot' -ErrorAction 'SilentlyContinue').Value
	if(!$scriptFolder)
	{
		if($MyInvocation.MyCommand.Path)
		{
			$scriptFolder = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
		}
	}
	if(!$scriptFolder)
	{
		if ($ExecutionContext.SessionState.Module.Path)
		{
			$scriptFolder = Split-Path (Split-Path $ExecutionContext.SessionState.Module.Path)
		}
	}

	# Return path.
	return $scriptFolder
}

Get-Module xDSCResourceDesigner | Remove-Module
Import-Module xDSCResourceDesigner -Force

$rootFolder = Join-Path -Path (Split-Path $(GetScriptPath)) -ChildPath 'DSCResources'
$resourceNames = Get-ChildItem $rootFolder -Directory | Select-Object -ExpandProperty Name

foreach($resourceName in $resourceNames)
{
    $targetFolder = Join-Path -Path '..\DSCResources' -ChildPath $resourceName
    $targetSchema = Join-Path -Path $targetFolder -ChildPath "$resourceName.schema.mof"
	Write-Output "Testing Resource $resourceName at $targetFolder"
	Test-xDscResource $targetFolder -Verbose:$IsVerbose
	Write-Output "Testing Schema $resourceName at $targetSchema"
    Test-xDscSchema $targetSchema -Verbose:$IsVerbose
}