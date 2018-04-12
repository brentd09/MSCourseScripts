# This will pull the BOFH excuse list and random an excuse and 
# speak it through the speaker

[Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null 
$webRaw = Invoke-WebRequest -uri "http://pages.cs.wisc.edu/~ballard/bofh/excuses"
$Excuses =  $webRaw.RawContent -split "`n" | Select-Object -skip 9 | Where-Object {$_ -notmatch "\/\\\'ex" }
$Excuse1 = Get-Random $Excuses
$Excuse2 = Get-Random $Excuses | where {$_ -ne $Excuse1}
$object = New-Object System.Speech.Synthesis.SpeechSynthesizer 
$object.SelectVoiceByHints('Male')
$phrase = "The problem you have with your computer was because of, " + $Excuse1 + " and " + $Excuse2
$object.Speak($phrase)
$object.Dispose()