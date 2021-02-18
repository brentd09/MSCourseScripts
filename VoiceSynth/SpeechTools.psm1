function Start-Talking {
  <#
  .SYNOPSIS
    Allows you to speak a sentence though the speaker of a windows computer
  .DESCRIPTION
    This command will record the current volume and mute states of a computer and then set the mute to $False
    and the volume to full and then will use the inbuilt speech synth to say a sentence of your choice. After 
    speaking it will again return the computer back to its original volume and mute states.
  .EXAMPLE
    Start-Talking -WhatToSay "I am speaking from a remote computer" -SendRemotely -ComputerName "Server1"
    Assuming the remoting is enabled, this command line will trigger a remote computer to say the sentence.
  .EXAMPLE
    Start-Talking -WhatToSay "I am speaking from within you local computer"
    This command will have the local computer say the sentence
  .PARAMETER   
  .INPUTS
    [string]
  .OUTPUTS
    Audio
  .NOTES
    General notes
      Created by: Brent Denny
      Created on: 18 Feb 2021
  #>
  [CmdletBinding(DefaultParameterSetName='Default')]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$WhatToSay,
    [Parameter(ParameterSetName='Remote',Mandatory=$true)]
    [switch]$SendRemotely,
    [Parameter(ParameterSetName='Remote',Mandatory=$true)]
    [string]$ComputerName
  )
  function Start-Voice {
    Param (
      [string]$Sentence
    )
    Add-Type -TypeDefinition @'
    using System.Runtime.InteropServices;
    
    [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioEndpointVolume {
      // f(), g(), ... are unused COM method slots. Define these if you care
      int f(); int g(); int h(); int i();
      int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
      int j();
      int GetMasterVolumeLevelScalar(out float pfLevel);
      int k(); int l(); int m(); int n();
      int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
      int GetMute(out bool pbMute);
    }
    [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDevice {
      int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
    }
    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceEnumerator {
      int f(); // Unused
      int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
    }
    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
    
    public class Audio {
      static IAudioEndpointVolume Vol() {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
        IAudioEndpointVolume epv = null;
        var epvid = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
        return epv;
      }
      public static float Volume {
        get {float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v;}
        set {Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty));}
      }
      public static bool Mute {
        get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
      }
    }
'@
    
    # Getting the current computers Audio values
    $InitialMute = [Audio]::Mute
    $InitialVolume = [Audio]::Volume
    
    [Audio]::Mute = $false
    [Audio]::Volume = 1
    
    [Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null 
    $Voice = New-Object System.Speech.Synthesis.SpeechSynthesizer 
    $Voice.SelectVoiceByHints('Male')
    $Voice.Speak($Sentence)
    $Voice.Dispose()
    
    [Audio]::Mute = $InitialMute
    [Audio]::Volume = $InitialVolume
  }
  
  if ($SendRemotely -eq $true) {
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Start-Voice -Sentence $Using:WhatToSay}
  }
  else {
    Start-Voice -Sentence $WhatToSay
  }
}