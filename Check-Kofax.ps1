#check file if exist = full version
$path = "C:\Program Files (x86)\Kofax\Power PDF 31\bin\Plug-Ins"
$path2 = "C:\Program Files (x86)\Nuance\Power PDF  30\bin\Plug-Ins"
$files = "FormTyper.zxt","Layer.zxt","Optimize.zxt","Retag.zxt","Watermark.zxt","ZAutoSave.zxt"
$txt = "\\vwspmsdt01\MDT_Logs\Kofax.txt"

$flag = 0

#Get-WmiObject -Class Win32_Product | where Name -match "Kofax Power PDF*" | select Name, Version
$Kofax = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {($_.DisplayName -match "Kofax Power PDF*") -or ($_.DisplayName -match "Nuance Power PDF*")} |  Select-Object DisplayName, DisplayVersion

#$Kofax.DisplayName.ToString()

if ( $Kofax -ne $null)
{  
    foreach($file in $files)
    {
        if (Test-Path "$path\$file" -PathType leaf)
        {
            $flag++
        }
        if (Test-Path "$path2\$file" -PathType leaf)
        {
            $flag++
        }
    }
    ##$flag

    if($flag -ge 6)
    {
        $result = "$env:computername," + $Kofax.DisplayName.ToString() + "," + $Kofax.DisplayVersion.ToString() + ",Kofax Full Version" | Out-File -FilePath $txt -Append
    }else{
        $result = "$env:computername," + $Kofax.DisplayName.ToString() + "," + $Kofax.DisplayVersion.ToString() + ",Kofax Standard Version" | Out-File -FilePath $txt -Append
    }
}else{
    $result = "$env:computername,No Kofax installed" | Out-File -FilePath $txt -Append

}
