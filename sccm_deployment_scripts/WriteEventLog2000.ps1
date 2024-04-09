#Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1
#Import-Module sqlserver

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

$ComputerTarget=$args[0]
#$EvendID=$args[1]
#$ComputerTarget = "test"

$password = "Secretus1519!" | ConvertTo-SecureString -asPlainText -Force
$username = "mpsc\pdq" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)

#write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id 2000 -ComputerName VWSPMSDT01
Invoke-Command -Computer "VWSPMSDT01" -ArgumentList $ComputerTarget -ScriptBlock { 

    param($Msg)

    write-eventLog -LogName MDT -Message $Msg -Source Trigger -id 2000 -ComputerName VWSPMSDT01

} -Credential $credential



#$ComputerTarget = "D08553-4MDY933"
#$EvendID="1003"
#(Get-Date).AddHours(-18) | Set-Date

# id 1001 = start PDQ deploy process
#write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id $EvendID -ComputerName VWSPMSDT01
#(Get-Date).AddHours(+18) | Set-Date
