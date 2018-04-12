# This will pull the BOFH excuse list and random an excuse and 
# speak it through the speaker

[Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null 
$webRaw = Invoke-WebRequest -uri "http://pages.cs.wisc.edu/~ballard/bofh/excuses"
$Excuses =  $webRaw.RawContent -split "`n" | Select-Object -skip 9 | Where-Object {$_ -notmatch "\/\\\'" }
$phrase = Get-Random $Excuses
$object = New-Object System.Speech.Synthesis.SpeechSynthesizer 
$object.SelectVoiceByHints('Female')
$object.Speak($phrase)