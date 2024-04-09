
$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

#$PackageList = ""

#$ComputerName=$args[0]
#$PackageName=$args[1]

$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

#$package = $PackageName
#$target = $ComputerName

#$event = Get-WinEvent -FilterHashtable @{Id=1005;LogName='MDT'} -MaxEvents 1
#$target = $event.Properties[0].Value
#$target = $target.ToString()
#Write-host $target 
#$package = "MPSC_NoActivation"

#$target = "D05886-4MDV933"


#Write-host $alive

  $PackageList = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $package, $target -ScriptBlock {

    param($Exe_Location, $package, $target)

    Set-Location -Path $Exe_Location;
    $lastexitcode = PDQDeploy.exe GetPackageNames;
    Return $lastexitcode
 
}

Remove-PSSession $sess

$PackageList 

#$PackageList.psobject.Properties["SyncRoot"].Value
#$TempList = $PackageList.psobject.Properties["SyncRoot"].Value  

#$TempList
#Write-Host $TempList2
#$PackageList.psobject.Properties
#$PackageList.GetType()
#$SoftwareList

#$PackageList
#Write-Host $PackageList





