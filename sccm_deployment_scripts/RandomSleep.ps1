#Pick a randominteger from an array then use it in Start-Sleep 
$Sleep_Time = 30, 60, 90, 120, 150, 180, 210, 240, 270, 300 | Get-Random

Start-Sleep -Seconds $Sleep_Time 