#check file if exist = full version

#$path = "C:\Program Files (x86)\Kofax\Power PDF 31\bin\Plug-Ins"
#$path2 = "C:\Program Files (x86)\Nuance\Power PDF  30\bin\Plug-Ins"
#$files = "FormTyper.zxt","Layer.zxt","Optimize.zxt","Retag.zxt","Watermark.zxt","ZAutoSave.zxt"
$keys = 'HKLM:\SOFTWARE\WOW6432Node\Nuance\PDF\GDoc', 'HKLM:\SOFTWARE\WOW6432Node\Kofax\PDF\GDoc'

$txt = "\\vwspmsdt01\MDT_Logs\Kofax31_20210903.txt"

$flag = 0
$readonly = 0

#Get-WmiObject -Class Win32_Product | where Name -match "Kofax Power PDF*" | select Name, Version
$Kofax = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {($_.DisplayName -match "Kofax Power PDF*") -or ($_.DisplayName -match "Nuance Power PDF*")} |  Select-Object DisplayName, DisplayVersion

#$Kofax.DisplayName.ToString()

if ( $Kofax -ne $null)
{ 
    
    foreach($key in $keys)
    {
        if ((Test-Path $key) -and ((Get-ItemProperty $key).ReadOnlyMode)){
            $readonly = (Get-ItemProperty -Path $key -Name ReadOnlyMode).ReadOnlyMode       
        }

    }
    ##$flag
       
    #if(Test-Path $key){
    #    $readonly = (Get-ItemProperty -Path $key -Name ReadOnlyMode).ReadOnlyMode           
    #} 

    if($readonly -ne 1)
    {
        $result = "$env:computername," + $Kofax.DisplayName.ToString() + "," + $Kofax.DisplayVersion.ToString() + ",Kofax Full Version" | Out-File -FilePath $txt -Append
    }else{
        $result = "$env:computername," + $Kofax.DisplayName.ToString() + "," + $Kofax.DisplayVersion.ToString() + ",Kofax Standard Version" | Out-File -FilePath $txt -Append
    }
}else{
    $result = "$env:computername,No Kofax installed" | Out-File -FilePath $txt -Append

}
