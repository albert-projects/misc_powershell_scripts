Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"
$Source_OU = "CN=VMWARE-TESTING,OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"

Move-ADObject -Identity $Source_OU -TargetPath "OU=Desktops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"