Configuration DeployWebServer {
  Param (
    [string]$ComputerName = 'LON-DC1',
    [string]$SourcePath = '\\LON-DC1\WebContent',
    [string]$DestinationPath = 'c:\inetpub\wwwroot'
  )
  node ($ComputerName) {
    WindowsFeature WebServerInstall {
      Ensure = 'Present'
      Name   = 'web-server'
    }

    File CopyWebSite {
      Ensure          = 'Present'
      SourcePath      = $SourcePath
      DestinationPath = $DestinationPath
      Recurse         = $true
      Force           = $true
      Type            = 'Directory'
      DependsOn       = '[WindowsFeature]WebServerInstall'
    }
  }
}

DeployWebServer -ComputerName Server6 

Start-DscConfiguration -Wait -Force -Verbose -Path .\DeployWebServer