
$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred


#$ComputerName=$args[0]
#$PackageName=$args[1]

$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

#$package = $PackageName
#$target = $ComputerName

$event = Get-WinEvent -FilterHashtable @{Id=1004;LogName='MDT'} -MaxEvents 1
$target = $event.Properties[0].Value
$target = $target.ToString()
#Write-host $target 
$package = "MPSC_Activation"

#$target = "D05886-4MDV933"


#Write-host $alive

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







