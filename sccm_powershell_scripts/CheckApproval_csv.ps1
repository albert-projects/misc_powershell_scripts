Import-Module ZTIUtility.psm1
$TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 

$ApprovalList = "\\VWSPMSDT01\MDT_Logs\approval.csv"

$csv = Import-Csv $ApprovalList
$ApprovalFlag = 0
$command = "cmd.exe /c exit 1"

Foreach ( $line in $csv ) {
    if ($TSenv.Value("SERIALNUMBER") -eq $line.SERIALNUMBER ) {
        $ApprovalFlag = 1
        $TSenv.Value("OSDComputername")= $line.ComputerName
    }
}

 if ($ApprovalFlag -eq 0 ) {
    iex $command
 }