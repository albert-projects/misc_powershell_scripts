Import-Module WDS


$event = Get-WinEvent -FilterHashtable @{Id=2001;LogName='MDT'} -MaxEvents 1
$MacAddress = $event.Properties[0].Value

#$MacAddress = "AA-BB-CC-DD-EE-FF"

Remove-WdsClient -DeviceID $MacAddress -Domain -DomainName "mpsc.nsw.gov.au" 

#