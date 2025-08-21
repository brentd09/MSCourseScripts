# Creating Modules and versioning them

- Steps to create a PowerShell module that will be autoloaded and versioned

  
1 Locate one of the autoloading directories from $env:PSModulePath variable
2 Create a folder under the autoloading directory the name of this folder must match the spelling of your module file
3 Create another directory under the directory that was created in the step 2, the name of this will be the version number
4 Save the module as a .psm1 file under the version number folder created in the previous step, the name of the psm1 file must match the directory created in step 2
  - example C:\Program Files\WindowsPowerShell\Modules\**BrentsADTools\1.0.1\BrentsADTools.psm1**
5 Create a module manifest file by running the following command

```PowerShell
New-ModuleManifest 

```
