
$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred


$ComputerName=$args[0]
$PackageName=$args[1]

$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

$package = $PackageName
$target = $ComputerName

#$package = "MPSC_Standard_Build_Software"
#$target = "D05886-4MDV933"

Invoke-Command -Session $sess -ArgumentList $Exe_Location, $package, $target -ScriptBlock {

  param($Exe_Location, $package, $target)

  #Start-Process PowerShell -Verb RunAs

  #$command = 'C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\PDQDeploy.exe Deploy -Package "MS Office 2016 Pro" -Targets "D05841-1QVS033"'
  Set-Location -Path $Exe_Location;
  PDQDeploy.exe Deploy -Package $package -Targets $target;
  
}

Remove-PSSession $sess







