Configuration AddPITagAccessControlExample
{
    Import-DscResource -Module PISecurityDSC
    
    # For use below in the multi-tag example.
    Import-Module OSIsoft.PowerShell
    $connection = Connect-PIDataArchive localhost
    # Any WhereClause accepted by Get-PIPoint can be used.
    #     Examples: "description:=*InternalCompanyUse*"
    #               "pointsource:=OPC"
    #               "pointsource:=OPC location1:=1"
    $tags = Get-PIPoint -Connection $connection -WhereClause "description:=*InternalCompanyUse*"
    $suffix = "_datasecurity"

    Node localhost
    {
        # A single tag can be specified in a straightforward manner.
        PIAccessControl PIAccessControl_SingleTag
        {
            Name = "ContractorsAndEmployeesTag"
            Identity = "Contractors"
            Type = "ptsecurity"
            Access = "Read"
            Ensure = "Present"
        }

        # Alternatively, multiple tags can be specified by using a foreach loop.
        # In this example, it is ensured that no tags designated for InternalCompanyUse are readable by Contractors.
        # This generates a set of PIAccessControls at the time of compilation; it does not automatically update when new tags are added.
        #      When new InternalCompanyUse tags are added, the DSC script should be recompiled.
        foreach ($tag in $tags) {
            $resourceName = "$($tag.Point.Name)$suffix"
            PIAccessControl $resourceName
            {
                Name = $($tag.Point.Name)
                Identity = "Contractors"
                Type = "datasecurity"
                Access = ""
                Ensure = "Present"
            }
        }
    }

    # Cleanly disconnect from PIDataArchive
    Disconnect-PIDataArchive -Connection $Connection
}
