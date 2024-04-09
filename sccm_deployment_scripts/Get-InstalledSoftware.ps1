
Function Get-InstalledSoftware {
    Param(
        [Alias('Computer','ComputerName','HostName')]
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true,
            Position=1
        )]
        [string]$Name = $env:COMPUTERNAME
    )
    Begin{
        $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
        $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser
    }
    Process{
        if (!(Test-Connection -ComputerName $Name -count 1 -quiet)) {
            Write-Error -Message "Unable to contact $Name. Please verify its network connectivity and try again." -Category ObjectNotFound -TargetObject $Computer
            Break
        }
        $masterKeys = @()
        $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($cuReg,$Name)
        $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($lmReg,$Name)
        foreach ($key in $lmKeys) {
            $regKey = $remoteLMRegKey.OpenSubkey($key)
            foreach ($subName in $regKey.GetSubkeyNames()) {
                foreach($sub in $regKey.OpenSubkey($subName)) {
                    $masterKeys += (New-Object PSObject -Property @{
                        "ComputerName" = $Name
                        "Name" = $sub.GetValue("displayname")
                        "SystemComponent" = $sub.GetValue("systemcomponent")
                        "ParentKeyName" = $sub.GetValue("parentkeyname")
                        "Version" = $sub.GetValue("DisplayVersion")
                        "UninstallCommand" = $sub.GetValue("UninstallString")
                        "InstallDate" = $sub.GetValue("InstallDate")
                        "RegPath" = $sub.ToString()
                    })
                }
            }
        }
        foreach ($key in $cuKeys) {
            $regKey = $remoteCURegKey.OpenSubkey($key)
            if ($regKey -ne $null) {
                foreach ($subName in $regKey.getsubkeynames()) {
                    foreach ($sub in $regKey.opensubkey($subName)) {
                        $masterKeys += (New-Object PSObject -Property @{
                            "ComputerName" = $Name
                            "Name" = $sub.GetValue("displayname")
                            "SystemComponent" = $sub.GetValue("systemcomponent")
                            "ParentKeyName" = $sub.GetValue("parentkeyname")
                            "Version" = $sub.GetValue("DisplayVersion")
                            "UninstallCommand" = $sub.GetValue("UninstallString")
                            "InstallDate" = $sub.GetValue("InstallDate")
                            "RegPath" = $sub.ToString()
                        })
                    }
                }
            }
        }
        $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
        $props = 'Name','Version','ComputerName','Installdate','UninstallCommand','RegPath'
        $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object $props | Sort-Object Name)
        $masterKeys
    }
    End{}
}


$file = "C:\Users\Public\Documents\mdt_log.txt"

$date = Get-Date
"MDT finish at: " + $date | Out-File -FilePath $file

"" | Out-File -FilePath $file -Append
"MDT installed Windows" | Out-File -FilePath $file -Append
Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object -MemberName Caption | Out-File -FilePath $file -Append
Get-ComputerInfo | select WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer | Out-File -FilePath $file -Append

"" | Out-File -FilePath $file -Append
"Below software were installed by PDQ deploy" | Out-File -FilePath $file -Append
"-------------------- " | Out-File -FilePath $file -Append

Get-InstalledSoftware | Select-Object -Property Name, Version  | Out-File -FilePath $file -Append

#Get-WmiObject -Class Win32_Product | Out-File -FilePath "C:\Users\Public\Documents\test.txt" -Append

"----------------------" | Out-File -FilePath $file -Append
"Log End" | Out-File -FilePath $file -Append