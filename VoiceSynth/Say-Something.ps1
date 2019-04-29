[CmdletBinding()]
Param (
  [Parameter(Mandatory=$true)]
  [string]$WhatToSay
)


[Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null 
$object = New-Object System.Speech.Synthesis.SpeechSynthesizer 
$object.SelectVoiceByHints('Male')
$object.Speak($WhatToSay)
$object.Dispose()