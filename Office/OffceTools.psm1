function Export-ExcelToPDF {
  <#
  .SYNOPSIS
    Automate xlsx to pdf after running a macro
  .DESCRIPTION
    This command opens a spreadsheet in Excel and executes a macro. This sheet then 
    gets saved as a PDF of the same name and directory as the xlsx file.
  .PARAMETER ExcelFilePath
    This is the full path the the .xlsx file that will be saved as a PDF file
    after the macro runs
  .PARAMETER MacroName
    This is the name of the macro that must be run when sheet is opened
  .EXAMPLE
    Export-ExcelToPDF -ExcelFilePath 'c:\file.xlsx' -MacroName 'Macro1'
    This will save the spreadsheet to a pdf in the path c:\file.pdf after 
    executing Macro1
  .EXAMPLE 
    Export-ExcelToPDF -ExcelFilePath 'c:\file.xlsx' -MacroName 'Macro1'
    This will save the spreadsheet to a pdf in the path c:\file.pdf after
    executing a default macro name.
  .NOTES
    General notes
      Created by: Brent Denny
      Created on 10 Feb 2020
    Ideas from the following sites helped me create this
      https://msdn.microsoft.com/en-us/library/bb149081.aspx
      https://www.excell-en.com/blog/2018/8/20/powershell-run-macros-copy-files-do-cool-stuff-with-power
  #>
  [cmdletbinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$ExcelFilePath,
    [string]$MacroName = 'MacroName'
  )
  if (Test-Path $ExcelFilePath) {
    $PdfFilePath = $ExcelFilePath -replace '^(.*)\.x[a-z]{2,3}$','$1.pdf'
    If ([string]::IsNullOrEmpty($PdfFilePath)) {break}
    $ExcelFixedFormat = 'Microsoft.Office.Interop.Excel.xlFixedFormatTypeù' -as [type]
    $ExcelComObj = New-Object -ComObject excel.application
    $ExcelComObj.visible = $false
    $ExcelWorkBook = $ExcelComObj.workbooks.open($ExcelFilePath, 3)
    $ExcelApp = $ExcelComObj.Application
    $ExcelApp.Run($MacroName)
    $ExcelWorkBook.Saved = $true
    "Saving PDF file $PdfFilePath"
    $ExcelWorkBook.ExportAsFixedFormat($ExcelFixedFormat::xlTypePDF, $PdfFilePath)
    $ExcelComObj.Workbooks.close()
    $ExcelComObj.Quit()
  }
}