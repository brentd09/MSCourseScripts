function Import-ExcelSpreadSheet {
  Param (
    [string]$ExcelFilePath = 'C:\test\Book1.xlsx',
    [string]$SpreadSheetName = 'Sheet1',
    [ValidateSet('MarkdownTable','CSV')]
    [string]$Format = 'MarkdownTable'
  )
  $ExcelObj  = New-Object -ComObject 'Excel.Application'
  $Workbook  = $ExcelObj.Workbooks.Open($ExcelFilePath)
  $WorkSheet = $Workbook.Sheets.Item($SpreadSheetName)
  $Cells     = $WorkSheet.Cells
  $Cells[1,1].Text
  $ColumnPos = 0
  [string[]]$Headers = @()
  do {
    $ColumnPos++
    If ($Cells[1,$ColumnPos].Text -ne '') {$Headers += $TableHeaders[1,$ColumnPos].Text}
    else { break }
  } while ($ColumnPos -lt 1000)
  # Need to get the rest of the SS and add it as objects to an object collection
}