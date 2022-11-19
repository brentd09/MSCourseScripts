function Copy-GitHubRepo {
  function Get-GitHubRepo {
    $Page = 1
    $AllRepos = @()
    do {
      $Repos = Invoke-RestMethod -Uri "https://api.github.com/orgs/MicrosoftLearning/repos?page=$Page&per_page=100"
      $Page++
      $AllRepos += $Repos
    } while ($Repos)
    return $AllRepos
  }
  
  $AllPublicRepos = Get-GitHubRepo |
    Where-Object {$_.name -match '^[A-Z]{2}-?[0-9]{3}-.*' -and $_.name -notmatch '.*\.[a-z]{2}-[a-z]{2}$'} |
    Sort-Object name 
  
    



}

function DownloadFilesFromRepo {
  Param(
    [string]$Owner,
    [string]$Repository,
    [string]$Path,
    [string]$DestinationPath
  )
  
  $baseUri = "https://api.github.com/"
  $UriPath = "repos/$Owner/$Repository/contents/$Path"
  $wr = Invoke-RestMethod -Uri $($baseuri+$UriPath)
  $objects = $wr.Content | ConvertFrom-Json
  $files = ($objects | Where-Object {$_.type -eq "file"}).download_url
  $directories = $objects | Where-Object {$_.type -eq "dir"}
  
  $directories | ForEach-Object { 
      DownloadFilesFromRepo -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath $($DestinationPath+$_.name)
  }
   
  if (-not (Test-Path $DestinationPath)) {
    # Destination path does not exist, let's create it
    try {New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop} 
    catch {throw "Could not create path '$DestinationPath'!"}
  }
  foreach ($file in $files) {
    $fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
    try {
      Invoke-WebRequest -Uri $file -OutFile $fileDestination -ErrorAction Stop -Verbose
      "Grabbed '$($file)' to '$fileDestination'"
    } 
    catch {throw "Unable to download '$($file.path)'"}
  }
}