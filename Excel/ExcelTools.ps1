function Import-ExcelSpreadSheet {
  Param (
    [string]$ExcelFilePath = 'C:\test\Book1.xlsx',
    [string]$SpreadSheetName = 'Sheet1',
    [ValidateSet('MarkdownTable','CSV')]
    [string]$Format = 'MarkdownTable'
  )
  [array]$ConvertedObj = New-Object -TypeName psobject

  $ExcelObj  = New-Object -ComObject 'Excel.Application'
  $Workbook  = $ExcelObj.Workbooks.Open($ExcelFilePath)
  $WorkSheet = $Workbook.Sheets.Item($SpreadSheetName)
  $Cells     = $WorkSheet.Cells
  $ColumnPos = 0
  [string[]]$Headers = @()
  do {
    $ColumnPos++
    If ($Cells[1,$ColumnPos].Text -ne '') {$Headers += $Cells[1,$ColumnPos].Text}
    else { break }
  } while ($ColumnPos -lt 1000)
  $Row = 2
  do {
    $ColNum = 0
    $HashTable = [System.Collections.Specialized.OrderedDictionary]::new()
    foreach ($Header in $Headers) {
      $ColNum++
      $Value = $Cells[$Row,$ColNum].Text
      $HashTable.Add($Header,$Value)
    }
    $RowObject = New-Object -TypeName psobject -Property $HashTable
    if ($Row -eq 2) {$ConvertedObj = $RowObject } 
    else {$ConvertedObj += $RowObject }
    $Row++
  } until ($Row -eq 150 -or $Cells[$Row,1].Text -eq '')
  return ($ConvertedObj )
}

Import-ExcelSpreadSheet