$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            Name = "IntegrationTempMapping"
            Identity = "IntegrationTempIdentity"
        }
    )
}

Configuration xAFMapping_Set
{
    param(
        [System.String] $Account,
        [System.String] $Description
    )

    Import-DscResource -ModuleName PISecurityDSC

    Node localhost
    {
        AFIdentity $($Node.Identity)
        {
            AFServer = $Node.NodeName
            Name = $($Node.Identity)
            Ensure = "Present"
            IsEnabled = $true
        }

        AFMapping xAFMapping_SetIntegration
        {
            AFServer = $Node.NodeName
            Name = $Node.Name
            Account = "NT Authority\" + $Account
            Identity = $Node.Identity
            Description = $Description
            Ensure = "Present"
            DependsOn = "[AFIdentity]$($Node.Identity)"
        }
    }
}

Configuration xAFMapping_Remove
{
    param()
    Import-DscResource -ModuleName PISecurityDSC

    Node localhost
    {
        AFMapping xAFMapping_RemoveIntegration
        {
            AFServer = $Node.NodeName
            Name = $Node.Name
            Ensure = "Absent"
        }
    }
}

Configuration xAFMapping_CleanUp
{
    param()
    Import-DscResource -ModuleName PISecurityDSC

    Node localhost
    {
        AFIdentity $($Node.Identity)
        {
            AFServer = $Node.NodeName
            Name = $($Node.Identity)
            Ensure = "Absent"
        }
    }
}