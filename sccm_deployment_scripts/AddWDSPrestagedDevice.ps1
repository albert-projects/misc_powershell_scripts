Import-Module WDS


$event = Get-WinEvent -FilterHashtable @{Id=2000;LogName='MDT'} -MaxEvents 1
$MacAddress = $event.Properties[0].Value

#$MacAddress = "C8-F7-50-8F-39-0E"

New-WdsClient -DeviceID $MacAddress -DeviceName $MacAddress -JoinRights JoinOnly -Domain "mpsc.nsw.gov.au" -JoinDomain $True -OU "OU=MDT-PrestagedDevices,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au" -User "MPSC\pdq" 

#pause