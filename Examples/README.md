# Example Configurations

For guidance on writing a DSC Configuration with resources from the PI Security DSC Module, please see the following articles in the Wiki. 
- [Writing a Configuration](https://github.com/osisoft/PI-Security-DSC/wiki/Writing-a-Configuration): Guidance on the structure and parameters of DSC Configurations.
- [Resource Reference](https://github.com/osisoft/PI-Security-DSC/wiki/Resource-Reference): Syntax for all resources is available in the module.

Since there are many ways to leverage DSC Resource in configurations, several example configurations are supplied in this folder.  The table below indicates the purposes for the example files.  
| Name | Description |
|---|---|
|[Resource]_[Action]|Capture simple functionality such as adding, updating, and removing the specified resource|
|PIDataArchive_AuditBaseline|Relatively simple configuration that applies several of the hardening measures identified by the PI Security Audit Tools|
|PIDataArchive_FSTS|Basic implementation of Windows Integrated Security in the PI Data Archive based off of KB01702|
|PIDataArchive_RBAC|An example of a more advanced configuration leveraging the xPIAccessControl resource to establish role-based access control|
|PIWebAPI_[Version]_SecurityBaseline|Security baseline settings for the named version of the PI Web API|