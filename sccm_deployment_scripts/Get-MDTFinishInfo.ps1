
$Str = "MDT finished at " 
$Str | Out-File -FilePath C:\log.txt
Get-Date | Out-File -FilePath C:\log.txt -Append

(Get-WmiObject -class Win32_OperatingSystem).Caption | Out-File -FilePath C:\log.txt -Append
Get-ComputerInfo  | select windowsversion | Out-File -FilePath C:\log.txt -Append


$Str = "Installed Software List"
$Str | Out-File -FilePath C:\log.txt -Append

$Str = "-----------------------"
$Str | Out-File -FilePath C:\log.txt -Append



