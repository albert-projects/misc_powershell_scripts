
$user = $env:UserName
$configfile = "C:\Users\$user\AppData\Roaming\Jabra Direct\config.json"
$configfile

if (Test-Path $configfile -PathType leaf)
{
    $json = Get-Content $configfile -raw | ConvertFrom-Json
    $json.DirectShowNotification | % {if($_.value -eq 'true'){$_.value='false'}}
    $json | ConvertTo-Json | set-content $configfile

    (Get-Content $configfile).replace('"value":  "false",', '"value":  false,') | Set-Content $configfile
    
    Write-Host "updated"    
}
