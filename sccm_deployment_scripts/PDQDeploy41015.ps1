

[cmdletbinding()]
param (
[parameter(mandatory = $false)] $TargetPC
)

#$ComputerName = $TargetPC

Write-Host "PDQ 41015"

$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

#$TargetPC=$args[0]

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
      MDT_FINISH='Y'
      ORDER BY Create_Datetime ASC
      ;"

#$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

#foreach($row in $result)
#{
#    $ComputerName = $row.Item('OSDCOMPUTERNAME')
#    $ComputerName = $ComputerName.Trim()
#    #Write-Host $ComputerName
#}

#$ComputerName=$args[0]
#$PackageName=$args[1]

$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

$package = "PDQ EventLog 41015"
$target = $TargetPC

#$package = "MPSC_Standard_Build_Software"
#$target = "D05886-4MDV933"



for($i=0; $i -le 10; $i++){

    Start-Sleep -Seconds 120

    $alive=Test-Connection -ComputerName $target -quiet
    #$alive=Test-Connection -ComputerName D05883-4MDY933 -quiet
    $alive.ToString()

    if($alive.ToString() -eq "True"){

        Invoke-Command -Session $sess -ArgumentList $Exe_Location, $package, $target -ScriptBlock {

          param($Exe_Location, $package, $target)

          #Start-Process PowerShell -Verb RunAs

          #$command = 'C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\PDQDeploy.exe Deploy -Package "MS Office 2016 Pro" -Targets "D05841-1QVS033"'
          Set-Location -Path $Exe_Location;
          PDQDeploy.exe Deploy -Package $package -Targets $target;

        }
        break
    }

}

Remove-PSSession $sess







