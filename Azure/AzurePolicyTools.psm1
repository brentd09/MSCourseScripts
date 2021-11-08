function Invoke-AzPolicyEvaluation {
  <#
  .SYNOPSIS
    This triggers the Azure Policy to trigger now
  .DESCRIPTION
    This triggers the Azure Policy to trigger now rather than 
    waiting for the the 1 hr cycle built into Azure
  .EXAMPLE
    Invoke-AzPolicyEvaluation
    This triggers the Policy evaluation within this subscription.
    You can locate the subscription ID by using the Get-AzSubscription PowerShell cmdlet
  .NOTES
    General notes
      Created by:   Brent Denny
      Created on:   07 Oct 2020
      Last Edited : 09 Nov 2021
      Original Source code from: https://www.miru.ch/how-to-manually-trigger-an-azure-policy-evaluation-cycle/
  #>
  Param()
  try {Get-AzSubscription -ErrorAction Stop}
  catch {Connect-AzAccount}
  try {$subscriptionId = (Get-AzSubscription -ErrorAction Stop).Id}
  catch {
    Write-Warning "Error accessing your Azure account"
    break
  }
  $PolicyInsights = Get-AzResourceProvider Microsoft.PolicyInsights  
  while ($PolicyInsights.RegistrationState -contains $false) {
    Write-Warning "Waiting for the Resource Provider to register"
    Start-Sleep -Seconds 15
  }
  $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2018-07-01-preview"
  $azContext = Get-AzContext
  $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
  $token = $profileClient.AcquireAccessToken($azContext.Tenant.Id)
  $authHeader = @{
      'Content-Type'='application/json'
      'Authorization'='Bearer ' + $token.AccessToken
  }
  Invoke-RestMethod -Method Post -Uri $uri -UseBasicParsing -Headers $authHeader -Debug
}