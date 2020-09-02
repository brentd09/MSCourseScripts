<#
.Synopsis
   Copy files to Azure Storage
.DESCRIPTION
   This script will copy all files from a given directory 
   along with the directory structure up to a blob store 
   in Azure
.EXAMPLE
   Copy-AzBlob -ContainerName Container1 -DirectoryPath c:\FilesToCopyToAzure -StorageAccountName brentstorageaccount1234
   The script will prompy you for your Storage Access Key an then will
   proceed to copy all of the files from your directiry into the blob
   store.
.PARAMETER ContainerName
   This is the name of the container within the storage account
.PARAMETER DirectoryPath
   This is the directory from where the files will be copied, the 
   entire directory structure is copied into the container
.PARAMETER StorageAccountName
   This is the unique name for the storage account 
.PARAMETER AccessKey
   The script will automatically prompt you for this key
   when you type the key into the console it will not show
   and be replaced with stars
.NOTES
   General notes
     Created by: Brent Denny
     Created on: 02 Sep 2020 
#>
[CmdletBinding()]
Param (
  [string]$AccessKey = (
    (New-Object System.Management.Automation.PSCredential (
      'name',(Read-Host -Prompt "Enter Access Key" -AsSecureString ))
    ).GetNetworkCredential().password
  ),
  [Parameter(Mandatory=$true)] 
  [string]$ContainerName,
  [Parameter(Mandatory=$true)]
  [string]$DirectoryPath,
  [Parameter(Mandatory=$true)]
  [string]$StorageAccountName
)
[array]$AZStorageModule = Get-Module Az.Storage
if ($AZStorageModule.Count -eq 0){Write-Warning "This script requires the AZ module to be installed, Install-Module az";break}
[array]$AZSubscription = Get-AzSubscription
if ($AZSubscription.Count -eq 0) {Connect-AzAccount}
if (Test-Path -Path $DirectoryPath -PathType Container) {
  try {
    $context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $AccessKey -Protocol Https -ErrorAction Stop
    $files = (Get-ChildItem $DirectoryPath -Recurse -ErrorAction Stop).FullName
    foreach($file in $files){Set-AzStorageBlobContent -Context $context -File $file -Container $ContainerName -Blob $file -ErrorAction Stop}
  }
  catch {Write-Warning 'There appears to be a problem transferring the files to the Azure storage'}
}
else {Write-Warning 'Please try again with a directory that exists'}