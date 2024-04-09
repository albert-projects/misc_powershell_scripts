
$txt = "\\vwspmsdt01\MDT_Logs\SD_testing.txt"
$time = Get-Date -format "dd-MMM-yyyy HH:mm"

$time | Out-File -FilePath $txt -Append


