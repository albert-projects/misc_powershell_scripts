Import-Module ActiveDirectory

$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTProgress"


$event = Get-WinEvent -FilterHashtable @{Id=3000;LogName='MDT'} -MaxEvents 1
$target = $event.Properties[0].Value
$target = $target.ToString()

$ComputerName1,$ComputerName2,$MacAddress, $ServiceTag = $target.split(',')


# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"
#$Source_OU = ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

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
      SERIALNUMBER='" + $ServiceTag + "'
      ORDER BY Create_Datetime ASC
      ;"

$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

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

 $c = Get-ADComputer $ComputerName1

if($c -ne $null) { 

    $Source_OU = Get-adcomputer -Identity $ComputerName1 | Select-Object -ExpandProperty DistinguishedName
    #write-host $Source_OU
    Move-ADObject -Identity $Source_OU -TargetPath $Target_OU

    if($ComputerType -eq "LAPTOP")
    {
        $member = "CN=" + $ComputerName1 + "," + $Target_OU
        #Add-ADGroupMember -Identity "Security-Access-Wifi-Corporate" -Members "CN=VM-005056A1D954,OU=Desktops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
        Add-ADGroupMember -Identity "Security-Access-Wifi-Corporate" -Members $member
    }


} 



$table = "dbo.MDTProgress"

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
      SERIALNUMBER='" + $ServiceTag + "'
      ORDER BY Create_Datetime ASC
      ;"

$result3 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

foreach($row in $result3)
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
        $ComputerType = "L"
            }
    if ($isDesktop -eq "True"){
        $ComputerType = "D"
    }
    if ($isVM -eq "True"){
        $ComputerType = "V"
    }
}

if( $ComputerName1.ToString().Length -ne 14 -or $ComputerName1.ToString().Substring($ComputerName1.ToString().Length -7, 7) -ne $ServiceTag)
{
    if($ComputerName1.ToString() -match '[a-zA-Z]\d\d\d\d\d' )
    {  
        $NewName = $ComputerType + $ComputerName1.ToString().Substring($ComputerName1.ToString().Length -5, 5) + "-" + $ServiceTag
    }
}else{
    
    $NewName = $ComputerName1

}


$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"
$variableName = "NewComputerName"
$variable = $NewName


Invoke-Command -Session $sess -ArgumentList $Exe_Location, $variableName, $variable -ScriptBlock {

    param($Exe_Location, $variableName, $variable )

    #Start-Process PowerShell -Verb RunAs

    #$command = 'C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\PDQDeploy.exe Deploy -Package "MS Office 2016 Pro" -Targets "D05841-1QVS033"'
    Set-Location -Path $Exe_Location;
    PDQDeploy.exe UpdateCustomVariable -Name $variableName -Value $variable;

}

Remove-PSSession $sess

$Sleep_Time = 60
Start-Sleep -Seconds $Sleep_Time 

#Add-Computer -DomainName mpsc.nsw.gov.au -ComputerName $Env:ComputerName -newname $name -OUPath $Target_OU -Credential $credential -Force -PassThru
#Rename-Computer -ComputerName $Env:ComputerName -newname $name -DomainCredential $credential -Force -PassThru
