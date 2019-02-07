[CmdletBinding()]
Param (
  [string]$Excuse = "none"
)
# This will pull the BOFH excuse list and random an excuse and 
# speak it through the speaker

[Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null 
$webRaw = Invoke-WebRequest -uri "http://pages.cs.wisc.edu/~ballard/bofh/excuses"
$Excuses =  $webRaw.RawContent -split "`n" | Select-Object -skip 9 | Where-Object {$_ -notmatch "\/\\\'ex" }
if ($Excuse -eq 'none') {$Excuse1 = Get-Random $Excuses}
else {$Excuse1 = $Excuse}
$object = New-Object System.Speech.Synthesis.SpeechSynthesizer 
$object.SelectVoiceByHints('Male')
$phrase = "The problem you have with your computer was because of, " + $Excuse1 
$object.Speak($phrase)
$object.Dispose()