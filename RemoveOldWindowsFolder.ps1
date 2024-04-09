#$path = $env:HOMEDRIVE+"\windows.old" 

$Drive = (Get-Partition | Where-Object {((Test-Path ($_.DriveLetter + ':\Windows.old')) -eq $True)}).DriveLetter
If ((Test-Path ($Drive + ':\Windows.old')) -eq $true) {
    $Directory = $Drive + ':\Windows.old'
    cmd.exe /c rmdir /S /Q $Directory
}

#If(Test-Path -Path $path) 
#{ 
    #create registry value 
    #$regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" 
    #New-ItemProperty -Path $regpath -Name "StateFlags1221" -PropertyType DWORD  -Value 2 -Force  | Out-Null 
    #start clean application 
    #cleanmgr /SAGERUN:1221 
#} 
Else 
{ 
    Write-Warning "There is no 'Windows.old' folder in system driver" 
    #cmd /c pause  
}