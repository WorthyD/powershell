# function vs($location) {
#   if ($location -eq $null) { $location = '.' }

#   $location = Get-Item $location

#   if ($location -is [System.IO.DirectoryInfo])
#   {
#   	$location = @(get-childitem $location -filter *.sln)[0]
#   }
  
#   if ($location -and [System.IO.Path]::GetExtension($location) -eq '.sln')
#   {
#   	Start-Process ('C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\devenv.exe') -ArgumentList $location.FullName -Verb RunAs
#   }
#   else
#   {
#   	Throw "Visual Studio solution file not found."
#   }
# }

