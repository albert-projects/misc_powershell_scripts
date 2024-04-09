#Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1
#Import-Module sqlserver

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

$password = "Secretus1519!" | ConvertTo-SecureString -asPlainText -Force
$username = "mpsc\pdq" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)

$ComputerTarget=$args[0]
#$EvendID=$args[1]
#$ComputerTarget = "test"
$ComputerName = Get-WMIObject -Class Win32_Bios | Select-Object -ExpandProperty PSComputername
$MacAddress = (Get-WmiObject Win32_NetworkAdapterConfiguration | where {$_.ipenabled -EQ $true}).Macaddress | select-object -first 1
$ServiceTag = get-ciminstance win32_bios | Select-Object -ExpandProperty SerialNumber

$Msg = $ComputerTarget=$args[0] + "," + $ComputerName + "," + $MacAddress + "," + $ServiceTag
Write-Host $Msg

#write-eventLog -LogName MDT -Message $Msg -Source Trigger -id 3000 -ComputerName VWSPMSDT01
Invoke-Command -Computer "VWSPMSDT01" -ArgumentList $Msg -ScriptBlock { 

    param($Msg)

    write-eventLog -LogName MDT -Message $Msg -Source Trigger -id 3000 -ComputerName VWSPMSDT01

} -Credential $credential

$Sleep_Time = 60
Start-Sleep -Seconds $Sleep_Time 

#$ComputerTarget = "D08553-4MDY933"
#$EvendID="1003"
#(Get-Date).AddHours(-18) | Set-Date

# id 1001 = start PDQ deploy process
#write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id $EvendID -ComputerName VWSPMSDT01
#(Get-Date).AddHours(+18) | Set-Date
