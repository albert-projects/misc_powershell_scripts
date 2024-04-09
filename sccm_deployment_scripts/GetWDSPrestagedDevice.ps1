#Import-Module ZTIUtility.psm1

#$TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
#$MacAddress = $TSenv.Value("MACADDRESS001")
#$MacAddress -replace ':','-'

#$MacAddress = "00-50-56-A1-D9-54"

#Remove-WdsClient -DeviceName $MacAddress -Domain -DomainName "mpsc.nsw.gov.au"
#Get-WdsClient -DeviceName $MacAddress -Domain -DomainName "mpsc.nsw.gov.au" | Select-Object -Property DeviceName

Get-WdsClient -Domain -DomainName "mpsc.nsw.gov.au" 