
$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

#$PackageList = ""

#$ComputerName=$args[0]
#$PackageName=$args[1]

$Exe_Location = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\"

#$package = $PackageName
#$target = $ComputerName

#$event = Get-WinEvent -FilterHashtable @{Id=1005;LogName='MDT'} -MaxEvents 1
#$target = $event.Properties[0].Value
#$target = $target.ToString()
#Write-host $target 
#$package = "MPSC_NoActivation"

#$target = "D05886-4MDV933"


#Write-host $alive

  $ComputerList = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $computer, $target -ScriptBlock {

    param($Exe_Location, $computer, $target)

    Set-Location -Path $Exe_Location;
    $lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
    Return $lastexitcode
 
}

Remove-PSSession $sess

$ComputerList 

#$PackageList.psobject.Properties["SyncRoot"].Value
#$TempList = $PackageList.psobject.Properties["SyncRoot"].Value  

#$TempList
#Write-Host $TempList2
#$PackageList.psobject.Properties
#$PackageList.GetType()
#$SoftwareList

#$PackageList
#Write-Host $PackageList





