

$Path = "HKCU:\Software\MapInfo\MapInfo\Professional\1900\Tools64"
$Location = "C:\Program Files\MapInfo\Professional\AddUser\Tools\MapUploaderV2\NRCreatorAddIn.mbx"
$ImageUri = "C:\Program Files\MapInfo\Professional\AddUser\Tools\MapUploaderV2\uploaderSmallIcon.png"
$Path2 = $Path + "\99999"

#delete current registry key
(Get-ChildItem -path $Path -Recurse | Where-Object {$_.GetValue("Title") -eq "Map Uploader"})| Remove-Item -Recurse

#create the key for MapInfo Map Uploader addin
New-Item -Path $Path -Name 99999 –Force
New-ItemProperty -Path $Path2 -Name "Title" -Value ”Map Uploader” -PropertyType String –Force
New-ItemProperty -Path $Path2 -Name "Location" -Value $Location -PropertyType String –Force
New-ItemProperty -Path $Path2 -Name "ImageUri" -Value $ImageUri -PropertyType String –Force
New-ItemProperty -Path $Path2 -Name "Description" -Value "The Spectrum Spatial Map Uploader transforms MapInfo Pro maps into resources ready for use in Spectrum Spatial." -PropertyType String –Force
New-ItemProperty -Path $Path2 -Name "Owner" -Value "" -PropertyType String –Force
New-ItemProperty -Path $Path2 -Name "Autoload" -Value "1" -PropertyType Dword –Force