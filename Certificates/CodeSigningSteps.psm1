function New-ScriptSignature {
  <#
  .SYNOPSIS
    This will digitally sign a script
  .DESCRIPTION
    This will digitally sign a chosen script with a chosen certificate, at the present 
    the certificate needs to be manually created here are the steps to create a 
    template from the Microsoft CA:
     1. Open the CA management console
     2. Right click on Certificate Templates and choose Manage
     3. Right click on the Code Signing Certificate and choose Dupicate
     4. Edit the duplicated Certificate Template and modify the following
          NAME of the certificate 
          SECURITY change who or what can enroll 
     5. Click OK on duplicated template
     6. Return to CA Console and right click on Certificate Templates
     7. Click New -> "Certificate Template to Issue" and select the newly duplicated certificate
     8. Run an MMC console and snapin Certificates for User certificates
     9. Open Personal -> Certificates 
    10. Right click Certifiicates -> All Tasks -> Request New Certificate
    11. Click next twice, select The Duplicated Certificate Template NAME -> Enroll
  .PARAMETER ScriptPath
    The path to and including the scriptname that will be digitally signed
  .EXAMPLE
    New-ScriptSignature -ScriptPath 'C:\scripts\NewScript.ps1'
    This will present a list of codesigning sertificates so that one can be selected 
    which will then digitally sign the C:\scripts\NewScript.ps1 script.
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 21 May 2021
  #>

  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    [string]$CertificateThumbprint
  )
  if ((Test-Path -Path $ScriptPath -PathType Leaf) -eq $true -and $ScriptPath -match '.*\.psm?1' ) {
    if ([string]::IsNullOrEmpty($CertificateThumbprint) -eq $true) {
      $CSCerts = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert 
    }
    else {
      $CSCerts = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object {$_.Thumbprint -eq $CertificateThumbprint}
    }
    if ($CSCerts.Count -gt 1) {
      $CSCert = $CSCerts | Select-Object -Property EnhancedKeyUsageList,Thumbprint,NotBefore,NotBefore,HasPrivateKey |
        Out-GridView -OutputMode Single -Title "Choose the correct certificate"
      Set-AuthenticodeSignature -Certificate $CSCert -FilePath $ScriptPath
    }
    elseif ($CSCerts.Count -eq 1) {
      $CSCert = $CSCerts[0]
      Set-AuthenticodeSignature -Certificate $CSCert -FilePath $ScriptPath
    }
    else {Write-Warning 'There are no Code Signing certificates available'}
  }
  else {Write-Warning 'The file path was not correct'}
}