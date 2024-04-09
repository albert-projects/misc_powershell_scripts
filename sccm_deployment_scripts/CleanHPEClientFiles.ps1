#Cache files
$HPE_Path_64  = "C:\Program Files\Hewlett Packard Entperise"
$HPE_Path_86  = "C:\Program Files (x86)\Hewlett Packard Entperise"
$CommonPath = "C:\HP Records Manager"

#Reg Key Path
$RegKeyPath= "HKLM:\Software\Hewlett-Packard" 


if (Test-Path $HPE_Path_64) {
  Remove-Item $HPE_Path_64 -Recurse -Force -Confirm:$false
}

if (Test-Path $HPE_Path_86) {
  Remove-Item $HPE_Path_86 -Recurse -Force -Confirm:$false
}

if (Test-Path $CommonPath) {
  Remove-Item $CommonPath -Recurse -Force -Confirm:$false
}

if (Test-Path $RegKeyPath) {
  Remove-Item $RegKeyPath -Recurse -Force -Confirm:$false
}


