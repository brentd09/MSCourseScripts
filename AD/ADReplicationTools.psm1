<#
  Functions in this module
    Get-ADObjectMeta
    Get-ADHighWaterMark
    Get-ADUpToDatenessVector
#>

function Get-ADObjectMeta {
<#
.SYNOPSIS
  Gets metadata from an AD object
.DESCRIPTION
  This shows all relevant infomation regarding attribute level replication 
.EXAMPLE
  Get-ADObjectMeta -UserName bob -ComputerName lon-dc1
  This command contacts the DC named lon-dc1 and finds the attribute data for the user bob
.NOTES
  General notes
  Created by: Brent Denny
  Created on: 10 Jul 2018
#>
  [cmdletbinding()]
  Param (
    $UserName = 'Administrator'
  )
  Get-ADUser -Filter {Name -eq $UserName} | 
    Get-ADReplicationAttributeMetadata -server lon-dc1 | 
      Select-Object  @{n='Attribute';e={$_.AttributeName}},
                     @{n='Server';e={$_.Server}},
                     @{n='LocalUSN';e={$_.LocalchangeUSN}},
                     @{n='OrigServer';e={$_.LastOriginatingChangeDirectoryServerInvocationId}},
                     @{n='OrigUSN';e={$_.LastOriginatingChangeUSN}},
                     @{n='ChangeTime';e={$_.LastOriginatingChangeTime}},
                     @{n='Version';e={$_.Version}}
} 
function Get-ADHighWaterMark {
<#
.SYNOPSIS
  Gets the High Water Mark database from the DC
.DESCRIPTION
  This shows all info stored in the HWM DB 
.EXAMPLE
  Get-ADHighWaterMArk -ComputerName lon-dc1
  This command contacts the DC named lon-dc1 and shows the contents of the HWM DB
.NOTES
  General notes
  Created by: Brent Denny
  Created on: 10 Jul 2018
#>
[cmdletbinding()]
  Param (
    [string]$ComputerName
  )
$ConvTemplate =@'
Default-First-Site-Name\LON-SVR1

DSA Options: IS_GC 

Site Options: (none)

DSA object GUID: df0b54eb-b71e-4277-a537-e40928fcca68

DSA invocationID: 79476b9b-55f9-4e58-91d2-86326d85a80f



==== INBOUND NEIGHBORS ======================================



{[string]NamingContext*:DC=Adatum,DC=com}

    {[string]Site:Default-First-Site-Name}\\{[string]DomainController:LON-DC1} via {[string]Protocol:RPC}

        DSA object GUID\: {[string]DSAGuid:9dea5320-9c83-4838-bbb6-fca0ca93f752}

        Last attempt @ {[string]LastReplicationAttempt:2018-08-01 22\:44\:12} was {[string]LastReplicationStatus:successful}.



{[string]NamingContext*:CN=Configuration,DC=Adatum,DC=com}

    {[string]Site:Default-First-Site-Name}\\{[string]DomainController:LON-DC1} via {[string]Protocol:RPC}

        DSA object GUID\: {[string]DSAGuid:9dea5320-9c83-4838-bbb6-fca0ca93f752}

        Last attempt @ {[string]LastReplicationAttempt:2018-08-01 21\:49\:37} was {[string]LastReplicationStatus:successful}.



{[string]NamingContext*:CN=Schema,CN=Configuration,DC=Adatum,DC=com}

    {[string]Site:Default-First-Site-Name}\\{[string]DomainController:LON-DC1} via {[string]Protocol:RPC}

        DSA object GUID\: {[string]DSAGuid:9dea5320-9c83-4838-bbb6-fca0ca93f752}

        Last attempt @ {[string]LastReplicationAttempt:2018-08-01 21\:45\:14} was {[string]LastReplicationStatus:successful}.
'@
  
  
  invoke-command -ComputerName $ComputerName {repadmin /showreps | ConvertFrom-String -TemplateContent $USING:ConvTemplate }
}
function Get-ADUpToDatenessVector {
<#
.SYNOPSIS
  Gets the Up To Dateness Vector database from the DC
.DESCRIPTION
  This shows all info stored in the UDV DB 
.EXAMPLE
  Get-ADUpToDatenessVector -ComputerName lon-dc1 -Partition 'dc=adatum,dc=com'
  This command contacts the DC named lon-dc1 and shows the contents of the UDV DB for the domain naming context
.NOTES
  General notes
  Created by: Brent Denny
  Created on: 10 Jul 2018
#>
  [cmdletbinding()]
  Param (
    [string]$ComputerName = 'localhost',
    [string]$PartitionName = '*'
  )
  $UDV = @()
  $AllResults = Get-ADReplicationUpToDatenessVectorTable -Target $ComputerName -Partition $PartitionName | 
                 Sort-Object -Property LastReplicationSuccess -Descending 
  foreach ($Result in $AllResults) {
    if (-not $UDV) {$UDV += $Result}
    elseif ($UDV.Partition -notcontains $Result.Partition) {$UDV += $Result} 
  }
  $UDV
}