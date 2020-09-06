 [CmdletBinding()]
 Param(
   [int]$MaxRecords = 20
 )
 
 Get-AzActivityLog -MaxRecord $MaxRecords -WarningAction SilentlyContinue | 
  Select-Object -Property @{n='ResourceID';e={($_.ResourceId )}}, 
                          @{n='OperationName';e={($_.OperationName.Value )}}, 
                          @{n='Status';e={$_.Status.Value}},
                          SubmissionTimestamp,
                          CorrelationId