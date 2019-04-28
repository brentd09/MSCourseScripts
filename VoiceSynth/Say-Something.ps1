[CmdletBinding()]
Param (
  [Parameter(Mandatory=$true)]
  [string]$WhatToSay
)
# This will pull the BOFH excuse list and random an excuse and 
# speak it through the speaker

[Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null 
$object = New-Object System.Speech.Synthesis.SpeechSynthesizer 
$object.SelectVoiceByHints('Male')
$object.Speak($WhatToSay)
$object.Dispose()