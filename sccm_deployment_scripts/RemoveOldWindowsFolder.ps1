
# schtasks.exe /Run /TN “\Microsoft\Windows\Servicing\StartComponentCleanup”
#this task only runs if the device is idle and on power. 
#this takes too long

<#
$path = $env:HOMEDRIVE+"\windows.old" 
If(Test-Path -Path $path) 
{ 
    #create registry value 
    $regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" 
    #New-ItemProperty -Path $regpath -Name "StateFlags1221" -PropertyType DWORD  -Value 2 -Force  | Out-Null 
    #start clean application 
    cleanmgr /SAGERUN:1221 
} 
Else 
{ 
    Write-Warning "There is no 'Windows.old' folder in system driver" 
    #cmd /c pause  
}
#>

$Drive = (Get-Partition | Where-Object {((Test-Path ($_.DriveLetter + ':\Windows.old')) -eq $True)}).DriveLetter
If ((Test-Path ($Drive + ':\Windows.old')) -eq $true) {
    $Directory = $Drive + ':\Windows.old'
    $Directory2 = $Directory + "\*"
    $Directory3 = $Directory + "\*.*"
    takeown /F $Directory2 /R /A /D Y  > $null
    Icacls $Directory3 /T /grant administrators:F > $null
    cmd.exe /c rmdir /S /Q $Directory > $null

    $regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" 
    New-ItemProperty -Path $regpath -Name "StateFlags1221" -PropertyType DWORD  -Value 2 -Force  | Out-Null 
    #start clean application 
    cleanmgr /SAGERUN:1221 

    #cleanmgr.exe /AUTOCLEAN
}

#If(Test-Path -Path $path) 
#{ 
    #create registry value 
    #$regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" 
    #New-ItemProperty -Path $regpath -Name "StateFlags1221" -PropertyType DWORD  -Value 2 -Force  | Out-Null 
    #start clean application 
    #cleanmgr /SAGERUN:1221 
#} 
#Else 
#{ 
#    Write-Warning "There is no 'Windows.old' folder in system driver" 
#    #cmd /c pause  
#}
