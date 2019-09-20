[DscLocalConfigurationManager()]
Configuration SetLCMToReapplyIfNotCompliant {
  Param ([string]$ComputerName)
  node $ComputerName {
    Settings {
      ConfigurationMode = 'ApplyAndAutoCorrect'
    }
  }
}

SetLCMToReapplyIfNotCompliant

Set-DscLocalConfigurationManager -Path .\SetLCMToReapplyIfNotCompliant