# Go to the user Registry
Set-Location hkcu:

# Create new registry key and give values 
New-ItemProperty -Path .\bob -Name sister  -Value "jill" -PropertyType String
Set-ItemProperty -Path .\bob -Name sister  -Value "Betty"

# Backup the Reg Key and modify values
Copy-Item -Path .\bob -Destination .\backupbob -Recurse
Set-ItemProperty -Path .\bob -Name sister  -Value "Bobo"

# Restore the RegKey, first need to remove the destination
Remove-Item -Path .\bob -Recurse -Confirm:$false
Copy-Item -Path .\backupbob -Destination .\bob -Recurse 
