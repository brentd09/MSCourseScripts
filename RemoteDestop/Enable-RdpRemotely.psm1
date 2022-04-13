function Enable-RDP {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$ComputerName = $env:COMPUTERNAME
  )
  
  begin {}
  
  process {
    foreach($Computer in $ComputerName) {
      try {
        $WMISplat = @{
          Class = 'Win32_TerminalServiceSetting'
          Namespace = 'root\CIMV2\TerminalServices' 
          Computer = $Computer 
          Authentication = 6 
          ErrorAction = 'Stop'
        }
        $RDP = Get-WmiObject @WMISplat # -Class 'Win32_TerminalServiceSetting' -Namespace 'root\CIMV2\TerminalServices' -Computer $Computer -Authentication 6 -ErrorAction  'Stop'
                              
      } 
      catch {
        Write-Verbose "$Computer : WMIQueryFailed"
        continue
      }
      
      if($RDP.AllowTSConnections -eq 1) {
        Write-Verbose "$Computer : RDP Already Enabled"
        continue
      } 
      else {
        try {
          $result = $RDP.SetAllowTsConnections(1,1)
          if($result.ReturnValue -eq 0) {
            Write-Verbose "$Computer : Enabled RDP Successfully"
          } 
          else {
            Write-Verbose "$Computer : Failed to enabled RDP"
          }
        } 
        catch {
          Write-Verbose "$computer : Failed to enabled RDP"
        }
      }
    }
  }
  end {}
}

