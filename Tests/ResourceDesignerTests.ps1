# ************************************************************************
# *
# * Copyright 2016 OSIsoft, LLC
# * Licensed under the Apache License, Version 2.0 (the "License");
# * you may not use this file except in compliance with the License.
# * You may obtain a copy of the License at
# *
# *   <http://www.apache.org/licenses/LICENSE-2.0>
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# *
# ************************************************************************

param(
    $IsVerbose = $false
)

function GetScriptPath {
    $scriptFolder = (Get-Variable 'PSScriptRoot' -ErrorAction 'SilentlyContinue').Value
    if (!$scriptFolder) {
        if ($MyInvocation.MyCommand.Path) {
            $scriptFolder = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
        }
    }
    if (!$scriptFolder) {
        if ($ExecutionContext.SessionState.Module.Path) {
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

foreach ($resourceName in $resourceNames) {
    $targetFolder = Join-Path -Path '..\DSCResources' -ChildPath $resourceName
    $targetSchema = Join-Path -Path $targetFolder -ChildPath "$resourceName.schema.mof"
    Write-Output "Testing Resource $resourceName at $targetFolder"
    Test-xDscResource $targetFolder -Verbose:$IsVerbose
    Write-Output "Testing Schema $resourceName at $targetSchema"
    Test-xDscSchema $targetSchema -Verbose:$IsVerbose
}