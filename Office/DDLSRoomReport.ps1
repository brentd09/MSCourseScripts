<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
[CmdletBinding()]
Param (
  [string]$FilePath = 'c:\qld.csv'
)
  
$RoomReport = Import-Csv $FilePath | Select-Object -Property   Room,
  CourseName, 
  @{n='Duration';e={$_.Duration -as [int]}},
  @{n='Trainer';e={if ($_.Instructor -ne 'Not Assigned'){$_.Instructor -replace '^(\w+)\s+(\w)\w+','$1$2'}else{'NA'}}},
  @{n='StartDate';e={$_.StartDate -as [datetime]}},
  @{n='EndDate';e={$_.EndDate -as [datetime]}},
  @{n='Bookings';e={"$($_.NumBookings)L $($_.RemoteStudents)T $($_.RemoteBookings1)Z"}}
$CurrentDate = Get-Date -Hour 0 -Minute 0 -Second 0
$MondayCorrection = 0 - ($CurrentDate.DayOfWeek.value__ - 1)
$MondayDate = ($CurrentDate.AddDays($MondayCorrection)).AddSeconds(-1)
$FridayDate = ($MondayDate.AddDays(4)).AddSeconds(1)
$RoomReport  | 
 Where-Object {$_.StartDate -ge $MondayDate -and $_.StartDate -le $FridayDate }  | 
 Sort-Object -Property Room,StartDate |
 Select-Object -Property *,@{n='Start';e={$_.StartDate.toShortDateString()}},@{n='End';e={$_.EndDate.toShortDateString()}}  -ExcludeProperty StartDate,EndDate |
 Format-Table


$excel = New-Object -ComObject excel.application
$excel.Visible = $true
$workbook = $excel.Workbooks.Add()
$WorkSheet = $workbook.Worksheets.Item(1)
$WorkSheet.Cells.Item(1,1) = "Week 13"
$WorkSheet.Cells.Item(2,1) = "Date 23/3/2020"
$Headers = 'TP','PAX','RM','TRAINER','COURSE','MON','TUE','WED','THU','FRI','Start time','Lunch time','Image','Notes'
[Hashtable[]]$RoomDetails = @{Number=1;PAX=12;TP='N'},@{Number=2;PAX=12;TP='Y'},@{Number=3;PAX=12;TP='Y'},
                      @{Number=4;PAX=16;TP='N'},@{Number=5;PAX=12;TP='N'},@{Number=6;PAX=6;TP='N'},
                      @{Number=7;PAX=4;TP='Y'},@{Number=8;PAX=2;TP='Y'},@{Number=9;PAX=9;TP='Y'},
                      @{Number=10;PAX=6;TP='Y'},@{Number=11;PAX=2;TP='Z'} 
[int[]]$RoomsInUse = @(01,02,03,04,07,07,08,08,09,09,10)
foreach ($Col in 0..13) {$WorkSheet.Cells.Item(3,($Col+1)) = $Headers[$Col]}
$Count=4

$RoomsInUse | ForEach-Object {
  $RoomNum = $_ - 1
  $WorkSheet.Cells.Item(($Count),1) = $RoomDetails[$RoomNum].TP
  $WorkSheet.Cells.Item(($Count),2) = $RoomDetails[$RoomNum].PAX
  $WorkSheet.Cells.Item(($Count),3) = $RoomDetails[$RoomNum].Number
  $Count++
}
$ColorHashGrey = @{
  Color = 14277081
  ColorIndex = 15
  Pattern = 1
  PatternColor = 0
  PatternColorIndex = -4105
  ThemeColor = 1
  TintAndShade = -0.149998474074526
  PatternThemeColor = 0
  PatternTintAndShade = 0
}
$TitleRange = $WorkSheet.Range('A1:N3') 
$WeekRange = $WorkSheet.Range('A1:N1')
$DateRange = $WorkSheet.Range('A2:N2')
$HeaderRange = $WorkSheet.Range('A3:N3') 

$TitleRange.interior.Color = $ColorHashGrey.Color
$TitleRange.interior.ColorIndex = $ColorHashGrey.ColorIndex
$TitleRange.interior.Pattern = $ColorHashGrey.Pattern
$TitleRange.interior.PatternColor = $ColorHashGrey.PatternColor
$TitleRange.interior.PatternColorIndex = $ColorHashGrey.PatternColorIndex
$TitleRange.interior.ThemeColor = $ColorHashGrey.ThemeColor
$TitleRange.interior.TintAndShade = $ColorHashGrey.TintAndShade
$TitleRange.interior.PatternThemeColor = $ColorHashGrey.PatternThemeColor
$TitleRange.interior.PatternTintAndShade = $ColorHashGrey.PatternTintAndShade
$WeekRange.BorderAround(1,2,0)
$DateRange.BorderAround(1,2,0)
$HeaderRange.BorderAround(1,2,0)
$Columns = "A3:A14","B3:B14","C3:C14","D3:D14","E3:E14","F3:F14","G3:G14","H3:H14","I3:I14","J3:J14","K3:K14","L3:L14","M3:M14","N3:N14"
0..13 | ForEach-Object {
  $ColumnRange = $WorkSheet.Range($Columns[$_])
  $ColumnRange.BorderAround(1,2,0)  
}
