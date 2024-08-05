<#
.SYNOPSIS
  This command finds Azure Roles that contain an action or a devolved action
.DESCRIPTION
  This command will find an Azure Role based on the Actions contained 
  within it. It will also check the NotActions to make sure the requested 
  action is not in this property. It will then devolve the action to include 
  a wildcard and also a wildcard with the original action as follows:
    Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete
    Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*
    Microsoft.Storage/storageAccounts/blobServices/containers/*/delete
    Microsoft.Storage/storageAccounts/blobServices/containers/*
    Microsoft.Storage/storageAccounts/blobServices/*/delete
    Microsoft.Storage/storageAccounts/blobServices/*
    Microsoft.Storage/storageAccounts/*/delete
    Microsoft.Storage/storageAccounts/*
    Microsoft.Storage/*/delete
    Microsoft.Storage/*
  It will then show all of the roles that contain any of these actions  
.EXAMPLE  
  Find-AzRoleFromAction -Action 'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete'

  This will find all Roles that have this action and not have this action in the 
  NotActions. If it cannot find the specific action, it will then devolove the 
  action to be more broad in its search.
    Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete
    Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*
    Microsoft.Storage/storageAccounts/blobServices/containers/*/delete
    Microsoft.Storage/storageAccounts/blobServices/containers/*
    Microsoft.Storage/storageAccounts/blobServices/*/delete
    Microsoft.Storage/storageAccounts/blobServices/*
    Microsoft.Storage/storageAccounts/*/delete
    Microsoft.Storage/storageAccounts/*
    Microsoft.Storage/*/delete
    Microsoft.Storage/*  
.EXAMPLE  
  Find-AzRoleFromAction -Action 'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete' -DevolutionLevel 2

  This will find all Roles that have this action and not have this action in the 
  NotActions. If it cannot find the specific action, it will then devolove the 
  action to be more broad in its search but it will only devolve two levels.
    Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete
    Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*
    Microsoft.Storage/storageAccounts/blobServices/containers/*/delete
    Microsoft.Storage/storageAccounts/blobServices/containers/*
.PARAMETER Action
  This is the action that needs to be found within an existing Azure Role.
  The Actions are in this format:
  Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete  
.NOTES
  Created By: Brent Denny
  Created on: 05-Aug-2024
#>

function Find-AzRoleFromAction {
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-z]+(\.[a-z]+)+(\/.*)+$')]
    [string]$Action,
    [int]$DevolutionLevel = 0 
  )
  function Resolve-Actions {
    Param ($ResolveAction)
    $DataArray = $ResolveAction -split '\/'
    $MaxIndex = $DataArray.Count - 2
    $FirstPass = $true
    $Actions = foreach ($Index in ($MaxIndex..0)) {
      if ($FirstPass -eq $true) {
        $ResolveAction
        ($DataArray[0..$Index] -join '/') + '/*'
        $FirstPass = $false
      }
      else {
        ($DataArray[0..$Index] -join '/') + '/*' + "/$($DataArray[-1])"
        ($DataArray[0..$Index] -join '/') + '/*'
      }
    }
    return $Actions
  }

  $PossibleRoles = @()
  $DevolvedActions = Resolve-Actions -ResolveAction $Action
  $DevolutionCount = 0
  foreach ($DevolvedAction in $DevolvedActions) {
    $DevolutionCount++
    Write-Verbose $DevolvedAction
    $Role = Get-AzRoleDefinition | Where-Object {$_.Actions -contains $DevolvedAction -and $_.NotActions -notcontains $Action}
    if ($Role.Count -gt 0) {$PossibleRoles += $Role}
    if ($DevolutionLevel -ne 0 -and $DevolutionCount -eq ($DevolutionLevel * 2)) {break} 
  }
  return $PossibleRoles
}
