#Import-Module ActiveDirectory
Import-Module ZTIUtility.psm1
#Import-Module \\VWSPMSDT01\MDT_Logs\ZTIUtility.psm1
#Import-Module \\VWSPMSDT01\DeploymentShare$\custom\MDTDB.psm1
Import-Module \\VWSPMSDT01\MDT_Logs\MDTDB.psm1

Connect-MDTDatabase -sqlServer VWSPMSDT01 -database MDT -instance SQLExpress -ErrorAction stop

$TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 

#New-MDTFinish -OSDCOMPUTERNAME 'aa' -MACADDRESS001 'bb' -MAKE 'cc' -MODEL 'dd' -SERIALNUMBER 'ee' -UUID 'ff' -ISVM 'gg' -ISLAPTOP 'hh' -ISDESKTOP 'ii' -MDT_FINISH 'Y'
New-MDTFinish -OSDCOMPUTERNAME $TSenv.Value("OSDComputername") -MACADDRESS001 $TSenv.Value("MACADDRESS001") -MAKE $TSenv.Value("MAKE") -MODEL $TSenv.Value("MODEL") -SERIALNUMBER $TSenv.Value("SERIALNUMBER") -UUID $TSenv.Value("UUID") -ISVM $TSenv.Value("ISVM") -ISLAPTOP $TSenv.Value("ISLAPTOP") -ISDESKTOP $TSenv.Value("ISDESKTOP") -MDT_FINISH 'Y'

#Start-Sleep -s 60
$Sleep_Time = 30, 60, 90, 120, 150, 180 | Get-Random
Start-Sleep -Seconds $Sleep_Time 

#$SQLServer = "VWSPMSDT01"
#$SQLDBName = "MDT"
#$Instance = "SQLEXPRESS"
#$pwd = "MDTConnect"
#$table = "dbo.MDTProgress"


#$queryStr = "INSERT INTO " + $table +
#             " (OSDCOMPUTERNAME, MACADDRESS001, MAKE, MODEL, SERIALNUMBER, UUID, ISVM, ISLAPTOP, ISDESKTOP, MDT_FINISH)
#             VALUES 
#             ('b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7', 'b8', 'b9', 'Y');"

# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"
#$Source_OU = "CN=VMWARE-TESTING,OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

#$SaveFile = "\\VWSPMSDT01\MDT_Logs\MoveOU\" + $TSenv.Value("OSDComputername") + ".txt"
#$TSenv.Value("OSDComputername") |Out-File $SaveFile

#$queryStr = "INSERT INTO " + $table +
#            " (OSDCOMPUTERNAME, MACADDRESS001, MAKE, MODEL, SERIALNUMBER, UUID, ISVM, ISLAPTOP, ISDESKTOP, MDT_FINISH)
#            VALUES
#            ('$TSenv.Value(""OSDComputername"")', '$TSenv.Value(""MACADDRESS001"")', '$TSenv.Value(""MAKE"")', '$TSenv.Value(""MODEL"")', '$TSenv.Value(""SERIALNUMBER"")', '$TSenv.Value(""UUID"")', '$TSenv.Value(""ISVM"")', '$TSenv.Value(""ISLAPTOP"")', '$TSenv.Value(""ISDESKTOP"")', 'Y');
#            "

#Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr


