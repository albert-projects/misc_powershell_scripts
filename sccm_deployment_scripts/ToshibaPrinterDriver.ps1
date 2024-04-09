#Write-Host $PSScriptRoot
$drivers = Get-ChildItem -Path "\\files\kits$\Drivers\Toshiba\esf6p.inf_amd64_b73619721d3651aa" -Recurse *.inf | Select-Object -ExpandProperty FullName
foreach ($driver in $drivers){
#Start-Process -Wait "C:\Windows\System32\pnputil.exe" -ArgumentList "/delete-driver oem85.inf /uninstall /force" -NoNewWindow
Start-Process -Wait "C:\Windows\System32\pnputil.exe" -ArgumentList "/add-driver `"$driver`" /install /subdirs" -NoNewWindow
Add-PrinterDriver "TOSHIBA Universal PS3" -Verbose}

#Add-Printer -Name "Find Me Printing Colour" -DriverName "TOSHIBA Universal PS3" -PortName "\\vpspadps01.mpsc.nsw.gov.au\Find Me Printing Colour"