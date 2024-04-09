Import-Module ZTIUtility.psm1
# Determine where to do the logging 
$TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $TSenv.Value("LogPath")  
$logFile = "$logPath\$($myInvocation.MyCommand).log"


# Start the logging 
Start-Transcript $logFile

# $TSenv.Value("OSDComputername")= $TSenv.Value("SerialNumber")
$SaveFile = "\\VWSPMSDT01\MDT_Logs\" + $TSenv.Value("OSDComputername") + ".txt"

Get-ChildItem TSENV: |Out-File $SaveFile

# Stop logging 
Stop-Transcript