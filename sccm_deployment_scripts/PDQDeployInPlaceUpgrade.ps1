
#Install-PackageProvider -Name "Nuget" -Force
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Register-PackageSource -Name PSNuGet -Location https://www.powershellgallery.com/api/v2 -ProviderName NuGet

#Install-Module -Name "SQLPS" -Force
#Update-Module SQLPS -Force
#Import-Module SqlServer -Force
Import-Module SQLPS -Force

$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTInPlaceUpgrade"

$event = Get-WinEvent -FilterHashtable @{Id=3001;LogName='MDT'} -MaxEvents 2
$target = $event.Properties[0].Value
$target = $target.ToString()
$ComputerTarget,$ComputerName,$MacAddress,$ServiceTag = $target.split(',')

#$ComputerTarget=$args[0]
#$EvendID=$args[1]
#$ComputerTarget = "test"
#$ComputerName = Get-WMIObject -Class Win32_Bios | Select-Object -ExpandProperty PSComputername
#$MacAddress = (Get-WmiObject Win32_NetworkAdapterConfiguration | where {$_.ipenabled -EQ $true}).Macaddress | select-object -first 1
#$ServiceTag = get-ciminstance win32_bios | Select-Object -ExpandProperty SerialNumber


Write-Host $ComputerTarget $ComputerName $MacAddress $ServiceTag


$queryStr = "SELECT TOP (1) 
       [id]
      ,[Create_Datetime]
      ,[NewName]
      ,[CurrentName]
      ,[MacAdress]
      ,[ServiceTag]
  FROM [MDT].[dbo].[MDTInPlaceUpgrade]
  order by Create_Datetime DESC;"

$result4 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr
foreach($row in $result4)
{
    $ServiceTag2 = $row.Item('ServiceTag')
    $ServiceTag2 = $ServiceTag2.Trim()
}

if($ServiceTag -eq $ServiceTag2){
    
    $target = $event.Properties[1].Value
    $target = $target.ToString()
    $ComputerTarget,$ComputerName,$MacAddress,$ServiceTag = $target.split(',')
    Write-Host $ComputerTarget $ComputerName $MacAddress $ServiceTag
}



$queryStr = "INSERT INTO " + $table +  "( NewName, CurrentName, MacAdress, ServiceTag ) VALUES ( '" + $ComputerTarget + "', '" + $ComputerName  + "', '" + $MacAddress + "', '" + $ServiceTag + "');"  

$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr


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
      ServicesTag='" + $ServiceTag + "'
      ORDER BY Create_Datetime DESC
      ;"

Write-Host $queryStr

$result2 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

foreach($row in $result2)
{
    $Task = $row.Item('MDT_TS')
    $Task = $Task.Trim()

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

#$result3 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

#foreach($row in $result3)
#{
#    $ComputerName = $row.Item('OSDCOMPUTERNAME')
#    $ComputerName = $ComputerName.Trim()
#    #Write-Host $ComputerName
#    $isLaptop = $row.Item('ISLAPTOP')
#    $isLaptop = $isLaptop.Trim()
#    $isDesktop = $row.Item('ISDESKTOP')
#    $isDesktop = $isDesktop.Trim()
#    $isVM = $row.Item('ISVM')
#    $isVM = $isVM.Trim()
#
#    if ($isLaptop -eq "True"){
#        $ComputerType = "L"
#            }
#    if ($isDesktop -eq "True"){
#        $ComputerType = "D"
#    }
#    if ($isVM -eq "True"){
#        $ComputerType = "V"
#    }
#}


#if( $ComputerTarget.ToString().Length -ne 14 -or $ComputerTarget.ToString().Substring($ComputerTarget.ToString().Length -7, 7) -ne $ServiceTag)
#{
#    if($ComputerTarget.ToString() -match '[a-zA-Z]\d\d\d\d\d' )
#    {  
#        $NewName = $ComputerType + $ComputerTarget.ToString().Substring($ComputerTarget.ToString().Length -5, 5) + "-" + $ServiceTag
#    }
#}else{
#    
#    $NewName = $ComputerTarget
#}


$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"
$variableName = "MDTTask"
$variable = $Task

Write-Host $Exe_Location
Write-Host $variableName
Write-Host $variable

Invoke-Command -Session $sess -ArgumentList $Exe_Location, $variableName, $variable -ScriptBlock {

    param($Exe_Location, $variableName, $variable )

    #Start-Process PowerShell -Verb RunAs

    #$command = 'C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\PDQDeploy.exe Deploy -Package "MS Office 2016 Pro" -Targets "D05841-1QVS033"'
    Set-Location -Path $Exe_Location;
    PDQDeploy.exe UpdateCustomVariable -Name $variableName -Value $variable;
    #PDQDeploy.exe UpdateCustomVariable -Name $variableName2 -Value $variable2;

}



#$queryStr = "UPDATE MDTInPlaceUpgradeTSList SET Enable='N' WHERE ServicesTag='" + $ServiceTag + "';"
#$result3 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr


Remove-PSSession $sess


$Sleep_Time = 60
Start-Sleep -Seconds $Sleep_Time 