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

<#
.SYNOPSIS

Evaluate whether a resource is absent or present.

.DESCRIPTION

Evaluate whether a resource is absent or present.

.EXAMPLE

Get-PIResource_Ensure -PIResource $PIResource

.PARAMETER PIResource

PI Resource object to evaluate presence of.

#>
function Get-PIResource_Ensure {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [object]
        $PIResource
    )

    if ($null -eq $PIResource) {
        $Ensure = "Absent"
    }
    else {
        $Ensure = "Present"
        Foreach ($Property in $($PIResource | Get-Member -MemberType Property | Select-Object -ExpandProperty Name)) {
            $RawValue = $PIResource | Select-Object -ExpandProperty $Property
            if ($null -eq $RawValue) {
                $Value = 'NULL'
            }
            else {
                $Value = $RawValue.ToString()
            }
            Write-Verbose "GetResult: $($Property): $($Value)."
        }
    }

    Write-Verbose "Ensure: $($Ensure)"

    return $Ensure
}

<#
.SYNOPSIS

Compare desired PI Data Archive ACL to current.

.DESCRIPTION

Compare desired PI Data Archive ACL to current. Implementation is
insensitive to the order of the entries.

.EXAMPLE

Compare-PIDataArchiveACL -Desired $Desired -Current $PIResource

.PARAMETER Desired

Desired ACL for the PI Data Archive object.

.PARAMETER Current

Current ACL for the PI Data Archive object.

#>
function Compare-PIDataArchiveACL {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $Desired,

        [parameter(Mandatory = $true)]
        [System.String]
        $Current
    )

    Write-Verbose "Testing desired: $Desired against current: $Current"

    return $($(Compare-Object -ReferenceObject $Desired.Split('|').Trim() -DifferenceObject $Current.Split('|').Trim()).Length -eq 0)
}

<#
.SYNOPSIS

Compare desired property values to current values.

.DESCRIPTION

Compare desired property values to currrent values. This comparison routine
takes into account the special cases associated with the ensure parameter.

.EXAMPLE

Compare-PIResourcePropertyCollection -Desired $Desired -Current $PIResource

.PARAMETER Desired

Desired set of property values for the resource.

.PARAMETER Current

Current set of property values for the resource.

#>
function Compare-PIResourcePropertyCollection {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)]
        [System.Object]
        $Desired,

        [parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Current
    )

    if ($Current.Ensure -eq 'Present' -and $Desired['Ensure'] -eq 'Present') {
        Foreach ($Parameter in $Desired.GetEnumerator()) {
            # Nonrelevant fields can be skipped.
            if ($Current.Keys -contains $Parameter.Key) {
                # Make sure all applicable fields match.
                Write-Verbose "Checking $($Parameter.Key) current value: ($($Current[$Parameter.Key])) against desired value: ($($Parameter.Value))"
                if ($($Current[$Parameter.Key]) -ne $Parameter.Value) {
                    Write-Verbose "Undesired property found: $($Parameter.Key)"
                    return $false
                }
            }
        }

        Write-Verbose "No undesired properties found."
        return $true
    }
    else {
        return $($Current.Ensure -eq 'Absent' -and $Desired['Ensure'] -eq 'Absent')
    }
}

<#
.SYNOPSIS

Identify parameters not specified in the configuration.

.DESCRIPTION

Identify parameters not specified in the configuration.  These
parameters should be preserved.  If these are not identified for
preservation, we risk overwriting them with default values.

.EXAMPLE

Set-PIResourceSavedParameterSet -pt $pt -sp $sp -cp $cp

.PARAMETER AFServer

Name of the target AF Server.

#>
function Set-PIResourceSavedParameterSet {
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [alias('pt')]
        [System.Collections.Hashtable]
        $ParameterTable,

        [parameter(Mandatory = $true)]
        [alias('sp')]
        [System.String[]]
        $SpecifiedParameters,

        [parameter(Mandatory = $true)]
        [alias('cp')]
        [System.Collections.Hashtable]
        $CurrentParameters
    )

    $CommonParameters = @('Ensure', 'PIDataArchive')
    # Start with the assumption that no values will be changed
    $ParametersToPreserve = $CurrentParameters
    # Explicitly specified parameters and common parameters should not be preserved.
    $ParametersToNotPreserve = $SpecifiedParameters + $CommonParameters
    Foreach ($Parameter in $ParametersToNotPreserve) {
        Write-Verbose "NotPreserving: $($Parameter)"
        $null = $ParametersToPreserve.Remove($Parameter)
    }
    # Now that we have the parameters we want to keep, set their values in the parameter table.
    Foreach ($Parameter in $ParametersToPreserve.GetEnumerator()) {
        Write-Verbose "Preserving: $($Parameter.Key): $($Parameter.Value)"
        $ParameterTable[$Parameter.Key] = $Parameter.Value
    }

    return $ParameterTable
}

<#
.SYNOPSIS

Connects to the AF Server using the AF SDK.

.DESCRIPTION

Connects to the AF Server using the AF SDK.  This function
acts as a wrapper, which is useful for reuse and testing.

.EXAMPLE

Connect-AFServerUsingSDK -AFServer localhost

.PARAMETER AFServer

Name of the target AF Server.

#>
function Connect-AFServerUsingSDK {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AFServer
    )

    $loaded = [System.Reflection.Assembly]::LoadWithPartialName("OSIsoft.AFSDK")
    if ($null -eq $loaded) {
        $ErrorActionPreference = 'Stop'
        throw "AF SDK could not be loaded"
    }

    $piSystems = New-Object OSIsoft.AF.PISystems
    if ($piSystems.Contains($AFServer)) {
        $AF = $piSystems[$AFServer]
    }
    else {
        $ErrorActionPreference = 'Stop'
        throw "Could not locate AF Server '$AFServer' in known servers table"
    }

    return $AF
}

<#
.SYNOPSIS

Outputs an AF path from an AF Element path and AF Server name.

.DESCRIPTION

Outputs an AF path from an AF Element path and AF Server name. The
server is omitted from the path in resources to make the specified
parameters consistent across resources.

.EXAMPLE

ConvertTo-FullAFPath -AFServer localhost -ElementPath 'OSIsoft\Machine'

.PARAMETER AFServer

Name of the AF Server hosting the AF Element.

.PARAMETER ElementPath

Path to an AF Element.

#>
function ConvertTo-FullAFPath {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AFServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ElementPath
    )

    $FullPath = "\\" + $AFServer.Trim("\") + "\" + $ElementPath.Trim("\")

    return $FullPath
}

<#
.SYNOPSIS

Wrapper to retrieve an AF Identity using the AF SDK.

.DESCRIPTION

Wrapper to retrieve an AF Identity using the AF SDK.  This approach
allows the call to be mocked for unit testing and separates the PS
Cmdlets from the AF SDK methods and properties.

.EXAMPLE

Get-AFIdentity -AFServer localhost -Name PIAdministrator

.PARAMETER AFServer

Name of the AF Server hosting the AF Identity.

.PARAMETER Name

Name of the AF Identity.

#>
function Get-AFIdentityDSC {
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $AFServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $AF = Connect-AFServerUsingSDK -AFServer $AFServer
    $identity = $AF.SecurityIdentities[$Name]

    return $identity
}

Export-ModuleMember -Function @(
    'Get-PIResource_Ensure',
    'Compare-PIDataArchiveACL',
    'Compare-PIResourcePropertyCollection',
    'Set-PIResourceSavedParameterSet',
    'Connect-AFServerUsingSDK',
    'ConvertTo-FullAFPath',
    'Get-AFIdentityDSC'
)