#Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

(Get-Date).AddHours(-18) | Set-Date

write-eventLog -LogName MDT -Message "TEST" -Source Trigger -id 1 -ComputerName VWSPMSDT01
