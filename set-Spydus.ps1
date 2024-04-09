
#get computer name
$CompName = $env:COMPUTERNAME

#path of spydus config file
$path = "C:\ProgramData\Desktop Management\PC Lockout\PCLockout.cfg"

if ($CompName -match "MOREE" ){

    #Write-Host $CompName
    $PC_Num = $CompName.Substring(6,$CompName.Length-7)
    Write-Host $PC_Num

    [xml] $config = get-content $path
    $item = $config.CONFIG.KEY | ? { $_.NAME -eq "MaterialCode" }
    $item.VALUE = $PC_Num

    $item = $config.CONFIG.KEY | ? { $_.NAME -eq "Host" }
    $item.VALUE = $CompName

    Set-Content $path -Value $config.InnerXml -Force

}