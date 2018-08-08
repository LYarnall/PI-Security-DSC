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

This example configuration covers a basic implementation of role-based access
control for the PI Data Archive.

.DESCRIPTION

This configuration is meant to configure a new install of a PI Data Archive to
use a standard implementation of Windows Integrated Security in the PI Data
Archive similat to the implementation documented in the Field Service Technical
Standard (KB01702).

.EXAMPLE

.\PIDataArchive_RBAC -NodeName "myPI" -PIAdministratorsPrincipals 'mydomain\PI Admins' -PIUsersPrincipals @('mydomain\Site A PI Users', 'mydomain\Site B PI Users')

.PARAMETER NodeName

Name of the PI Data Archive server.

.PARAMETER PIAdministratorsPrincipals

Windows identities to associate with an administrative role in PI.  Ideally, this
should be a single AD group.

.PARAMETER PIUsersPrincipals

Windows identities to associate with a read only user role in PI.  Ideally, this
should be a single AD group.

.PARAMETER PIBuffersPrincipals

Windows identities to associate with instances of PI Buffer Subsystem.  Ideally, this
should be a single AD group.

.PARAMETER PIInterfacesPrincipals

Windows identities to associate with PI Interfaces.  Ideally, this should be a single AD group.

.PARAMETER PIPointsAnalysisCreatorPrincipals

Windows identities to associate with a power user role in PI for those who need to
create PI Points.  Ideally, this should be a single AD group.

.PARAMETER PIWebAppsPrincipals

Windows identities to associate with PI Web Applications such as PI Vision.  Ideally,
this should be a single AD group.

.PARAMETER PIConnectorRelaysPrincipals

Windows identities to associate with PI Connector Relays.  Ideally,
this should be a single AD group.

.PARAMETER PIDataCollectionManagersPrincipals

Windows identities to associate with PI Data Collection Managers.  Ideally,
this should be a single AD group.

#>
Configuration PIDataArchive_RBAC
{
    param(
        [String]
        $NodeName = 'localhost',

        [String[]]
        $PIAdministratorsPrincipals = @('BUILTIN\Administrators', 'NT Authority\System'),

        [String[]]
        $PIUsersPrincipals = '\Everyone',

        [String[]]
        $PIBuffersPrincipals = '',

        [String[]]
        $PIInterfacesPrincipals = '',

        [String[]]
        $PIPointsAnalysisCreatorPrincipals = '',

        [String[]]
        $PIWebAppsPrincipals = '',

        [String[]]
        $PIConnectorRelaysPrincipals = '',

        [String[]]
        $PIDataCollectionManagersPrincipals = '',

        [Boolean]
        $PIBatchRequired = $false,

        [Boolean]
        $PILegacyAppsRequired = $false

    )

    Import-DscResource -ModuleName PISecurityDSC

    Node $NodeName
    {
        #region Lists of security objects
        $PIDatabases = @('PIDBSEC', 'PIPOINT', 'PIUSER', 'PIDS', 'PIReplication', 'PIARCADMIN', 'PIARCDATA', 'PIBACKUP', 'PIAUDIT', 'PIMSGSS', 'PITUNING', 'PITRUST', 'PIMAPPING')
        if ($PIBatchRequired) {
            $PIDatabases += @('PIHeadingSets', 'PIBatch', 'PICampaign', 'PITransferRecords', 'PIBATCHLEGACY')
        }
        if ($PILegacyAppsRequired) {
            $PIDatabases += @('PIAFLINK', 'PIMODULES')
        }
        $DefaultPIPoints = @('SINUSOID', 'SINUSOIDU', 'CDT158', 'CDM158', 'CDEP158', 'BA:TEMP.1', 'BA:LEVEL.1', 'BA:CONC.1', 'BA:ACTIVE.1', 'BA:PHASE.1')
        #endregion

        #region Role based rules for Identities
        $Identities = @(
            @{
                Name           = 'piadmins'
                Description    = 'Identity for administrative users of PI'
                Mappings       = $PIAdministratorsPrincipals
                DatabaseAccess = @{ ReadWrite = $PIDatabases }
                PointAccess    = 'ReadWrite'
                DataAccess     = 'ReadWrite'
            },
            @{
                Name           = 'PI Buffers'
                Description    = 'Identity for PI Buffer Subsystem and PI Buffer Server'
                Mappings       = $PIBuffersPrincipals
                DatabaseAccess = @{ ReadWrite = 'PIPOINT' }
                PointAccess    = 'ReadWrite'
                DataAccess     = 'ReadWrite'
            },
            @{
                Name           = 'PI Interfaces'
                Description    = 'Identity for PI Interfaces'
                Mappings       = $PIInterfacesName
                DatabaseAccess = @{ Read = 'PIPOINT' }
                PointAccess    = 'Read'
                DataAccess     = 'Read'
            },
            @{
                Name           = 'PI Users'
                Description    = 'Identity for the Read-only users'
                Mappings       = $PIUsersPrincipals
                DatabaseAccess = @{ Read = @('PIDBSEC', 'PIPOINT', 'PIUSER', 'PIDS', 'PIModules', 'PIHeadingSets', 'PIBatch', 'PICampaign', 'PITransferRecords', 'PIBATCHLEGACY') }
                PointAccess    = 'Read'
                DataAccess     = 'Read'
            },
            @{
                Name           = 'PI Points and Analysis Creator'
                Description    = 'Identity for PIACEService, PIAFService and users that can create and edit PI Points'
                Mappings       = $PIPointsAnalysisCreatorPrincipals
                DatabaseAccess = @{ ReadWrite = @('PIPOINT', 'PIDS') }
                PointAccess    = 'ReadWrite'
                DataAccess     = 'ReadWrite'
            }
            @{
                Name           = 'PI Web Apps'
                Description    = 'Identity for PI Vision, PI Web API, and PI Web API Crawler'
                Mappings       = $PIWebAppsPrincipals
                DatabaseAccess = @{ Read = @('PIDBSEC', 'PIPOINT', 'PIUSER', 'PIMAPPING') }
                PointAccess    = 'Read'
                DataAccess     = 'Read'
            },
            @{
                Name           = 'PI Connector Relays'
                Description    = 'Identity for PI Connector Relays'
                Mappings       = $PIConnectorRelaysPrincipals
                DatabaseAccess = @{
                    Read      = 'PIUSER'
                    ReadWrite = @('PIPOINT', 'PIDS')
                }
                PointAccess    = 'ReadWrite'
                DataAccess     = 'ReadWrite'
            },
            @{
                Name           = 'PI Data Collection Managers'
                Description    = 'Identity for PI Data Collection Managers'
                Mappings       = $PIDataCollectionManagersPrincipals
                DatabaseAccess = @{ Read = @('PIDBSEC', 'PIDS', 'PIPOINT', 'PIREPLICATION', 'PIUSER') }
                PointAccess    = 'Read'
                DataAccess     = 'Read'
            }
        )
        #endregion

        #region Create PI Identities, create PI Mappings, and assign permissions
        Foreach ($Identity in $Identities) {
            # Only process a role if there is a mappi; a role is useless without any mappings.
            if (![System.String]::IsNullOrEmpty($Identity.Mappings)) {
                # Create the role as a PI Identity
                PIIdentity "Set_$($Identity.Name)" {
                    Name               = $($Identity.Name)
                    Description        = $($Identity.Description)
                    IsEnabled          = $true
                    CanDelete          = $false
                    AllowUseInMappings = $true
                    AllowUseInTrusts   = $true
                    Ensure             = "Present"
                    PIDataArchive      = $NodeName
                }
                # Create all the associated PI Mappings
                Foreach ($Mapping in $Identity.Mappings) {
                    if (![System.String]::IsNullOrEmpty($Mapping)) {
                        PIMapping "Set_$Mapping" {
                            Name          = $Mapping
                            PrincipalName = $Mapping
                            Identity      = $Identity.Name
                            Enabled       = $true
                            Ensure        = "Present"
                            PIDataArchive = $NodeName
                            DependsOn     = "[PIIdentity]Set_$($Identity.Name)"
                        }
                    }
                }
                # Define the PI Database Security
                Foreach ($AccessLevel in $Identity.DatabaseAccess.GetEnumerator()) {
                    $DatabaseNames = $AccessLevel.Value
                    $AccessString = $AccessLevel.Key
                    Foreach ($Database in $DatabaseNames) {
                        PIAccessControl "$($Identity.Name)_$Database" {
                            Name      = $Database
                            Type      = "PIDatabaseSecurity"
                            Ensure    = "Present"
                            Identity  = $Identity.Name
                            Access    = $AccessString
                            DependsOn = "[PIIdentity]Set_$($Identity.Name)"
                        }
                    }
                }
                # Define security for default PI Points
                Foreach ($Point in $DefaultPIPoints) {
                    PIAccessControl "$($Identity.Name)_PtSecurity_$Point" {
                        Name      = $Point
                        Type      = "PtSecurity"
                        Ensure    = "Present"
                        Identity  = $Identity.Name
                        Access    = $Identity.PointAccess
                        DependsOn = "[PIIdentity]Set_$($Identity.Name)"
                    }

                    PIAccessControl "$($Identity.Name)_DataSecurity_$Point" {
                        Name      = $Point
                        Type      = "DataSecurity"
                        Ensure    = "Present"
                        Identity  = $Identity.Name
                        Access    = $Identity.DataAccess
                        DependsOn = "[PIIdentity]Set_$($Identity.Name)"
                    }
                }
            }
        }
        #endregion

        #region Clean up default PI Identities
        Foreach ($Database in $PIDatabases) {
            # Remove piadmin from the ACLs since it always has full access.
            PIAccessControl "piadmin_$Database" {
                Name     = $Database
                Type     = "PIDatabaseSecurity"
                Ensure   = "Absent"
                Identity = "piadmin"
            }
            # Remove PIWorld from ACLs since it is disabled in this configuration.
            PIAccessControl "PIWorld_$Database" {
                Name     = $Database
                Type     = "PIDatabaseSecurity"
                Ensure   = "Absent"
                Identity = "PIWorld"
            }
        }
        # Delete the unused default identities
        $DefaultIdentitiesToDelete = @('PIOperators', 'PISupervisors', 'PIEngineers', 'pidemo')
        Foreach ($DefaultIdentity in $DefaultIdentitiesToDelete) {
            PIIdentity "Delete_$DefaultIdentity" {
                Name          = $DefaultIdentity
                Ensure        = "Absent"
                PIDataArchive = $NodeName
            }
        }
        # Disable PIWorld and piusers
        $DefaultIdentitiesToDisable = @('PIWorld', 'piusers')
        Foreach ($DefaultIdentity in $DefaultIdentitiesToDisable) {
            PIIdentity "Delete_$DefaultIdentity" {
                Name             = $DefaultIdentity
                IsEnabled        = $false
                AllowUseInTrusts = $false
                Ensure           = "Present"
                PIDataArchive    = $NodeName
            }
        }
        #endregion
    }
}