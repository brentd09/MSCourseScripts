Get-WMIObject -class Win32_ComputerSystem -ComputerName (Get-ADComputer -filter *).name -ea SilentlyContinue | 
  Select-Object DNSHostName,Username | Format-List