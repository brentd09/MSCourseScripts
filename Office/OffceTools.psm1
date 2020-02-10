function Export-ExcelToPDF {
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