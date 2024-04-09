#Install-Module -Name SqlServer -Force -Confirm:$false
#Update-Module SqlServer -Force -Confirm:$false
#Install-PackageProvider -Name "Nuget" -Force
#Install-Module -Name "SqlServer" -Force
#Update-Module SqlServer -Force
#Import-Module SqlServer -Force


$name=$args[0]
$NewName=$args[1]

$password = "Secretus1519!" | ConvertTo-SecureString -asPlainText -Force
$username = "mpsc\pdq" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)

$CurrComputerName = Get-WMIObject -Class Win32_Bios | Select-Object -ExpandProperty PSComputername
$CurrMacAddress = (Get-WmiObject Win32_NetworkAdapterConfiguration | where {$_.ipenabled -EQ $true}).Macaddress | select-object -first 1
$CurrServiceTag = get-ciminstance win32_bios | Select-Object -ExpandProperty SerialNumber


$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
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
      SERIALNUMBER='" + $CurrServiceTag + "'
      ORDER BY Create_Datetime ASC
      ;"

#$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

#foreach($row in $result)
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

$mark = 0

if( $name.ToString().Length -ne 14 -or $name.ToString().Substring($name.ToString().Length -7, 7) -ne $CurrServiceTag)
{
    # For Lenovo PC, it have 8 digits serial number
    if( $name.ToString().Length -ne 15 -or $name.ToString().Substring($name.ToString().Length -8, 8) -ne $CurrServiceTag)
    {
        if( $name.ToString() -notlike 'T0[0-9][0-9][0-9][0-9]' )
        {
            if($name.ToString() -match '[a-zA-Z]\d\d\d\d\d' )
            {    
                #$NewName = $ComputerType + $name.ToString().Substring($name.ToString().Length -5, 5) + "-" + $CurrServiceTag
                Rename-Computer -ComputerName $name -newname $NewName -DomainCredential $credential -Force -PassThru

                $mark = 1

                #Restart computer
                Restart-Computer -Force
            }
        }
    }

    #Rename-Computer -ComputerName $Env:ComputerName -newname $name -DomainCredential $credential -Force -PassThru

}

if ($mark -eq 0)
{
  Write-Host "No Change PC Name"  

}

#Add-Computer -DomainName mpsc.nsw.gov.au -ComputerName $Env:ComputerName -newname $name -OUPath $Target_OU -Credential $credential -Force -PassThru
#Rename-Computer -ComputerName $Env:ComputerName -newname $name -DomainCredential $credential -Force -PassThru

#Move-ADObject -Identity $Source_OU -TargetPath $Target_OU