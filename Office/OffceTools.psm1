function Export-ExcelToPDF {
  <#
  .SYNOPSIS
    Automate xlsx to pdf
  .DESCRIPTION
    Long description
    https://msdn.microsoft.com/en-us/library/bb149081.aspx
  .PARAMETER ExcelFilePath
    This is the full path the the .xlsx file that will be saved as a PDF file
  .EXAMPLE
    Export-ExcelToPDF -ExcelFilePath c:\file.xlsx
    This will save the spreadsheet to a pdf in the path c:\file.pdf
  .NOTES
    General notes
      Created by: Brent Denny
      Created on 10 Feb 2020
  #>
  [cmdletbinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$ExcelFilePath
  )
  if (Test-Path $ExcelFilePath) {
    $PdfFilePath = $ExcelFilePath -replace '^(.*)\.x[a-z]{2,3}$','$1.pdf'
    If ([string]::IsNullOrEmpty($PdfFilePath)) {break}
    $ExcelFixedFormat = “Microsoft.Office.Interop.Excel.xlFixedFormatType” -as [type]
    $ExcelComObj = New-Object -ComObject excel.application
    $ExcelComObj.visible = $false
    $ExcelWorkBook = $ExcelComObj.workbooks.open($ExcelFilePath, 3)
    $ExcelWorkBook.Saved = $true
    "Saving PDF file $PdfFilePath"
    $ExcelWorkBook.ExportAsFixedFormat($ExcelFixedFormat::xlTypePDF, $PdfFilePath)
    $ExcelComObj.Workbooks.close()
    $ExcelComObj.Quit()
  }
}