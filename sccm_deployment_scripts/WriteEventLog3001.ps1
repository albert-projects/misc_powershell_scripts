#Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1
#Import-Module sqlserver

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"


#set random sleep timer
#$rnd = Get-Random -Minimum 1 -Maximum 600
#Start-Sleep -Seconds $rnd


$password = "Secretus1519!" | ConvertTo-SecureString -asPlainText -Force
$username = "mpsc\pdq" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)

$ComputerTarget=$args[0]
#$EvendID=$args[1]

$ComputerName = Get-WMIObject -Class Win32_Bios | Select-Object -ExpandProperty PSComputername
$MacAddress = (Get-WmiObject Win32_NetworkAdapterConfiguration | where {$_.ipenabled -EQ $true}).Macaddress | select-object -first 1
$ServiceTag = get-ciminstance win32_bios | Select-Object -ExpandProperty SerialNumber

$msg = $ComputerTarget + "," + $ComputerName  + "," + $MacAddress + "," + $ServiceTag
#$msg2 = $ServiceTag + ",InPlaceUpgrade"

#write-eventLog -LogName MDT -Message $msg -Source Trigger -id 3001 -ComputerName VWSPMSDT01
Invoke-Command -Computer "VWSPMSDT01" -ArgumentList $msg -ScriptBlock { 

    param($Msg)

    write-eventLog -LogName MDT -Message $Msg -Source Trigger -id 3001 -ComputerName VWSPMSDT01

} -Credential $credential



#write-eventLog -LogName MDT -Message $msg2 -Source Trigger -id 3002 -ComputerName VWSPMSDT01

$Sleep_Time = 60
Start-Sleep -Seconds $Sleep_Time 

$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTApprovalList"

$queryStr = "SELECT TOP (1)
       [id]
      ,[Create_Datetime]
      ,[COMPUTERNAME]
      ,[SERIALNUMBER]
      ,[MACADDRESS1]
      ,[MACADDRESS2]
      ,[MODEL]
      ,[TYPE]
      ,[BUNDLESOFTWARE]
      ,[ACTIVATION]
      ,[Enable]
      FROM " + $table + " WHERE
      COMPUTERNAME='" + $ComputerTarget + "'
      ORDER BY Create_Datetime DESC
      ;"

#Write-Host $queryStr

#$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

<#
foreach($row in $result)
{
    $ComputerName = $row.Item('COMPUTERNAME')
    $ComputerName = $ComputerName.Trim()
    #Write-Host $ComputerName
    $BundleSoftware = $row.Item('BUNDLESOFTWARE')
    $BundleSoftware = $BundleSoftware.Trim()
    $Activation = $row.Item('ACTIVATION')
    $Activation = $Activation.Trim()

    if($BundleSoftware -eq "Y"){
        write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id 1001 -ComputerName VWSPMSDT01
    }
    if($BundleSoftware -eq "N"){
        write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id 1002 -ComputerName VWSPMSDT01
    }

}
#>



#$ComputerTarget = "D08553-4MDY933"
#$EvendID="1003"
#(Get-Date).AddHours(-18) | Set-Date

# id 1001 = start PDQ deploy process
#write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id $EvendID -ComputerName VWSPMSDT01
#(Get-Date).AddHours(+18) | Set-Date
