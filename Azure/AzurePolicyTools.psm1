function Invoke-AzPolicyEvaluation {
  <#
  .SYNOPSIS
    This triggers the Azure Policy to trigger now
  .DESCRIPTION
    This triggers the Azure Policy to trigger now rather than 
    waiting for the the 1 hr cycle built into Azure
  .EXAMPLE
    Invoke-AzPolicyEvaluation -$SubscriptionId 12342113-1234-4491-80c6-1234f54182b5
    This triggers the Policy evaluation within this subscription.
    You can locate the subscription ID by using the Get-AzSubscription PowerShell cmdlet
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 07 Oct 2020
      Original Source code from: https://www.miru.ch/how-to-manually-trigger-an-azure-policy-evaluation-cycle/
  #>
  Param (
    [Parameter(Mandatory=$true)]
    [ValidatePattern('[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')]
    [string]$SubscriptionId 
    
  )
  $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2018-07-01-preview"
  try {$azContext = Get-AzContext -ErrorAction Stop}
  catch {
    try {
      Connect-AzAccount -ErrorAction stop
      $azContext = Get-AzContext -ErrorAction Stop
    }
    catch {
      Write-Warning 'Access to Azure was not initiated correctly'
      break
    }
  }
  $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
  $token = $profileClient.AcquireAccessToken($azContext.Tenant.Id)
  $authHeader = @{
      'Content-Type'='application/json'
      'Authorization'='Bearer ' + $token.AccessToken
  }
  Invoke-RestMethod -Method Post -Uri $uri -UseBasicParsing -Headers $authHeader
}