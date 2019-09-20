[DscLocalConfigurationManager()]
Configuration SetLCMToReapplyIfNotCompliant {
  Param ([string]$ComputerName = 'LON-DC1')
  node $ComputerName {
    Settings {
      ConfigurationMode = 'ApplyAndAutoCorrect'
    }
  }
}

SetLCMToReapplyIfNotCompliant -ComputerName Server6

Set-DscLocalConfigurationManager -Path .\SetLCMToReapplyIfNotCompliant