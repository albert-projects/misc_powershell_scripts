

[cmdletbinding()]
param (
[parameter(mandatory = $false)] $TargetPC,
[parameter(mandatory = $false)] $MacAddress
)


#$TargetPC = "A4BB6D9EB80F"
#$MacAddress = "A4:BB:6D:9E:B8:0F"
#$ComputerName = $TargetPC

Write-Host "PDQ In-Place-Upgrade Follow Up"
Write-Host "PC: " $TargetPC
Write-Host "MacAddress: " $MacAddress

$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

#$TargetPC=$args[0]

$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTInPlaceUpgrade"


$queryStr = "SELECT TOP (1) 
       [id]
      ,[Create_Datetime]
      ,[NewName]
      ,[CurrentName]
      ,[MacAdress]
      ,[ServiceTag]
      FROM " + $table + " WHERE
      MacAdress='" + $MacAddress + "'
      ORDER BY Create_Datetime DESC
      ;"

$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

foreach($row in $result)
{
    $ComputerName = $row.Item('CurrentName')
    $ComputerName = $ComputerName.Trim()
    #Write-Host $ComputerName
}

#$ComputerName=$args[0]
#$PackageName=$args[1]

$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

$package = "In-Place_Upgrade_FollowUpProcess"
$target = $ComputerName

#$package = "MPSC_Standard_Build_Software"
#$target = "D05886-4MDV933"



for($i=0; $i -le 10; $i++){

    Write-Host $target
    Write-host $MacAddres

    Start-Sleep -Seconds 60

    $alive=Test-Connection -ComputerName $target -quiet
    #$alive=Test-Connection -ComputerName D05883-4MDY933 -quiet
    $alive.ToString()

    if($alive.ToString() -eq "True"){

          Write-Host "Reset workstation Admin"
          $script = $PSScriptRoot+"\ResetWorkstationAdmin.ps1"
          & $script -TargetPC $target 

          Restart-Computer -ComputerName $target -Force 

          for($j=0; $j -le 20; $j++){         
                
                Write-Host "sleep 60, $j"
                Start-Sleep -Seconds 60
                    if ( Test-Connection -ComputerName $target -Count 1 -Quiet){
                    $alive2 = "Y"
                    Write-Host "Rebooted and online. deploy follow up process"
                    break
                }

          }

          Start-Sleep -Seconds 60
            
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






