#Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1
#Import-Module sqlserver

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

$event = Get-WinEvent -FilterHashtable @{Id=1003;LogName='MDT'} -MaxEvents 1
$ComputerTarget = $event.Properties[0].Value


#$ComputerTarget=$args[0]
#$EvendID=$args[1]


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

$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

foreach($row in $result)
{
    $ComputerName = $row.Item('COMPUTERNAME')
    $ComputerName = $ComputerName.Trim()
    #Write-Host $ComputerName
    $BundleSoftware = $row.Item('BUNDLESOFTWARE')
    $BundleSoftware = $BundleSoftware.Trim()
    $Activation = $row.Item('ACTIVATION')
    $Activation = $Activation.Trim()

    if($Activation -eq "Y"){
        write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id 1004 -ComputerName VWSPMSDT01
    }
    if($Activation -eq "N"){
        write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id 1005 -ComputerName VWSPMSDT01
    }

}




#$ComputerTarget = "D08553-4MDY933"
#$EvendID="1003"
#(Get-Date).AddHours(-18) | Set-Date

# id 1001 = start PDQ deploy process
#write-eventLog -LogName MDT -Message $ComputerTarget -Source Trigger -id $EvendID -ComputerName VWSPMSDT01
#(Get-Date).AddHours(+18) | Set-Date
