Import-Module ZTIUtility.psm1
Import-Module \\VWSPMSDT01\MDT_Logs\MDTDB.psm1

Connect-MDTDatabase -sqlServer VWSPMSDT01 -database MDT -instance SQLExpress -ErrorAction stop

$TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 

$onList = ""
$onList = Get-Approval -MACADDRESS2 $TSenv.Value("MACADDRESS001")

#$SQLServer = "VWSPMSDT01"
#$SQLDBName = "MDT"
#$Instance = "SQLEXPRESS"
#$pwd = "MDTConnect"
#$table = "dbo.MDTApprovalList"

$ApprovalFlag = 0
$command = "cmd.exe /c exit 1"

#$queryStr = "SELECT TOP (10) 
#       [id]
#      ,[Create_Datetime]
#      ,[COMPUTERNAME]
#      ,[SERIALNUMBER]
#      ,[MACADDRESS1]
#      ,[MACADDRESS2]
#      ,[MACHINETYPE]
#      ,[Enable]
#      FROM " + $table + " WHERE
#      SERIALNUMBER='4MDV933'
#      ;"


#$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr


if($onList -ne "") {
   $ApprovalFlag = 1
   $TSenv.Value("OSDComputername") = $onList
}


 if ($ApprovalFlag -eq 0 ) {
    iex $command
 }