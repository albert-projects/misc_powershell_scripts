Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1

$barcode = "Dummy"
$SerialNumber = ""
$ADComputerName = "Dummy"

$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTApprovalList"


$event = Get-WinEvent -FilterHashtable @{Id=41016;LogName='Application'} -MaxEvents 1 | Where-Object -Property Message -Match 'Deployment started for computer'
$EventMacAddress = $event.Properties[0].Value
$EventMacAddress = $EventMacAddress.substring(32,12)
$EventMacAddress = $EventMacAddress.insert(10,":")
$EventMacAddress = $EventMacAddress.insert(8,":")
$EventMacAddress = $EventMacAddress.insert(6,":")
$EventMacAddress = $EventMacAddress.insert(4,":")
$EventMacAddress = $EventMacAddress.insert(2,":")
write-host $EventMacAddress


#$event = Get-WinEvent -FilterHashtable @{Id=3001;LogName='MDT'} -MaxEvents 1
#$target = $event.Properties[0].Value
#$target = $target.ToString()
#$ComputerTarget,$ComputerName,$MacAddress, $ServiceTag = $target.split(',')


$queryStr = "SELECT 
       [id]
      ,[Create_Datetime]
      ,[COMPUTERNAME]
      ,[SERIALNUMBER]
      ,[MACADDRESS1]
      ,[MACADDRESS2]
      ,[Enable]
      FROM " + $table + " WHERE
      MACADDRESS2='" + $EventMacAddress + "'
      ;"


$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

#$ApprovalList = "\\VWSPMSDT01\MDT_Logs\approval.csv"
#$csv = Import-Csv $ApprovalList
$ApprovalFlag = 0


foreach($row in $result)
{
    $ComputerName = $row.Item('COMPUTERNAME')
    $ComputerName = $ComputerName.Trim()
    $ApprovalFlag = 1
    $ADComputerName = $ComputerName
    $SerialNumber = $row.Item('SERIALNUMBER')
    $SerialNumber = $SerialNumber.Trim()
    $barcode = "*" + $ComputerName.Substring(1,5) + "*"
}


Write-Host $barcode
write-host $SerialNumber
$Enable = ""
$table = "dbo.MDTInPlaceUpgradeTSList"

$queryStr = "SELECT TOP (1)
       [id]
      ,[Create_Datetime]
      ,[MacAddress1]
      ,[MacAddress2]
      ,[Model]
      ,[ServicesTag]
      ,[MDT_TS]
      ,[Enable]
      FROM " + $table + " WHERE 
      Enable='Y' AND 
      MacAddress2='" + $EventMacAddress + "'
      ORDER BY Create_Datetime DESC
      ;"

$result2 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

foreach($row in $result2)
{
    $Enable = $row.Item('Enable')
    $Enable = $Enable.Trim()

}

Write-Host $Enable


if( $Enable -eq "Y"){

    #in-place upgrade
    $queryStr = "UPDATE MDTInPlaceUpgradeTSList SET Enable='N' WHERE MacAddress2='" + $EventMacAddress + "';"
    $result3 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr


    #move pc to PrestagedDevices OU
    #

$queryStr = "SELECT TOP (1) 
       [id]
      ,[Create_Datetime]
      ,[NewName]
      ,[CurrentName]
      ,[MacAdress]
      ,[ServiceTag]
      FROM [MDT].[dbo].[MDTInPlaceUpgrade]
      WHERE [MacAdress]='" + $EventMacAddress + "'
      ORDER BY Create_Datetime DESC
        ;"


    #$result4 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

    #foreach($row in $result4)
    #{
    #    $CurrentName = $row.Item('CurrentName')
    #    $CurrentName = $CurrentName.Trim()
    #
    #}

    #Get-ADComputer $CurrentName | Move-ADObject -TargetPath "OU=MDT-PrestagedDevices,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
    #

}else{

    #New MDT deployment
    $c = Get-ADComputer -Filter 'Name -like $barcode'

    if($c -ne $null) { 

        Get-ADComputer -Filter 'Name -like $barcode' | Remove-ADComputer -Confirm:$False
        #Remove-ADComputer -Identity $ADComputerName -confirm:$false
        #Move-ADObject -Identity $Source_OU -TargetPath $Target_OU
        #Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $UpdateStr
        #if (Test-Path $FileName) {
        #    Remove-Item $FileName
        #}
    } 

    #Foreach ( $line in $csv ) {
    #    if ($EventMacAddress -eq $line.MacAddress ) {
    ##        $ApprovalFlag = 1
    #        $ADComputerName = $line.ComputerName
    #    }
    #}

    #Write-Host $ADComputerName
    try{
        $c =  @(Get-ADComputer $ADComputerName)

        if($c.Count -eq 1) { 
            Write-Host "The computer is already in AD."
            Remove-ADComputer -Identity $ADComputerName -confirm:$false
            #Move-ADObject -Identity $Source_OU -TargetPath $Target_OU
            #Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $UpdateStr
            #if (Test-Path $FileName) {
            #    Remove-Item $FileName
            #}
        } 
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
    # newcomputername not found
    Write-Host "The computer is not in AD."    
}

}


<#


$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTProgress"

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"
$Source_OU = ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

$queryStr = "SELECT TOP (1) 
       [id]
      ,[Create_Datetime]
      ,[OSDCOMPUTERNAME]
      ,[MACADDRESS001]
      ,[MAKE]
      ,[MODEL]
      ,[SERIALNUMBER]
      ,[UUID]
      ,[ISVM]
      ,[ISLAPTOP]
      ,[ISDESKTOP]
      ,[MDT_FINISH] 
      FROM " + $table + " WHERE
      MDT_FINISH='Y'
      ORDER BY Create_Datetime ASC
      ;"

#$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr
<#
foreach($row in $result)
{
    $ComputerName = $row.Item('OSDCOMPUTERNAME')
    $ComputerName = $ComputerName.Trim()
    #Write-Host $ComputerName
    $isLaptop = $row.Item('ISLAPTOP')
    $isLaptop = $isLaptop.Trim()
    $isDesktop = $row.Item('ISDESKTOP')
    $isDesktop = $isDesktop.Trim()
    $isVM = $row.Item('ISVM')
    $isVM = $isVM.Trim()

    if ($isLaptop -eq "True"){
        $ComputerType = "LAPTOP"
        $Target_OU = "OU=Laptops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
    }
    if ($isDesktop -eq "True"){
        $ComputerType = "DESKTOP"
        $Target_OU = "OU=Desktops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
    }
    if ($isVM -eq "True"){
        $ComputerType = "VM"
        $Target_OU = "OU=Desktops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
    }
}



#looking for the folder
$folder = "\\VWSPMSDT01\MDT_Logs\MoveOU"

foreach($file in Get-ChildItem -Path "$folder")
{
    $FileName = $folder + "\" + $file
    $ComputerName = Get-Content "$FileName"
    #Write-Host $ComputerName
    $Source_OU = "CN=" + $ComputerName + $Source_OU
  
    #Write-Host $Source_OU


$UpdateStr = "UPDATE " + $table + 
       " SET MDT_FINISH = 'N'
       WHERE OSDCOMPUTERNAME = '" + $ComputerName + "';"

 # write-host $UpdateStr

 $Source_OU = "CN=" + $ComputerName + $Source_OU
 
}


Start-Sleep -Seconds 120
Restart-Computer -ComputerName $ComputerName -Force

Start-Sleep -Seconds 60

$message = "C:\windows\system32\msg.exe * Finished the MDT process on " + $ComputerName 
Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $message -ComputerName $ComputerName

#>