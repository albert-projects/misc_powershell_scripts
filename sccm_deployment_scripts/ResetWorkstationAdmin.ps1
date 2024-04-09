<#
    .Synopsis 
        Reset workstation local administrator passwords.
        
    .Description
        This script gets a list of computers from AD and adds a local sysadmin account while disabling the builtin administrator or admin account.
 
    .Parameter InputFile    
        optional The full path of the text file name where computer account names are stored. Ex: C:\temp\computers.txt.  If omitted, uses AD.
        
    .Example
        ResetWorkstationAdmins.ps1 -InputFile c:\temp\Computers.txt
		
		This prompts you for the new password two times and updates the local sysadmin password on all computers to that.
       
    .Example
        ResetWorkstationAdmins.ps1 -InputFile c:\temp\Computers.txt -Verbose
        
        This tells you what exactly happening at every stage of the script.
        
    .Notes
        Based On: Update-LocalAdministratorPassword.ps1 by Sitaram Pamarthi (http://techibee.com)
        Modified for MPSC by: Stephen Needham

#>

#Test Input File is "C:\dev\powershell\input\Workstations.txt"



[cmdletbinding()]
param (
[parameter(mandatory = $false)] $InputFile="C:\DeploymentShare\Scripts\custom\Workstations.txt",
[parameter(mandatory = $false)] $TargetPC,
[parameter(mandatory = $false)] $OutputDirectory="C:\DeploymentShare\Scripts\custom\",
[parameter(mandatory = $false)] $UserName='sysadmin',
[parameter(mandatory = $false)] $Group='Administrators'
)

$ComputerTarget=$args[0]

$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTApprovalList"

$queryStr = "SELECT TOP (1) 
       [id]
      ,[Create_Datetime]
      ,[OSDCOMPUTERNAME]
      ,[MACADDRESS001]
      ,[MAKE]
      ,[MODEL]
      ,[SERIALNUMBER]
      ,[UUID]
      ,[ISVM]
      ,[ISLAPTOP]
      ,[ISDESKTOP]
      ,[MDT_FINISH] 
      FROM " + $table + " WHERE
      MDT_FINISH='Y'
      ORDER BY Create_Datetime ASC
      ;"


#$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

#foreach($row in $result)
#{
#    $ComputerName = $row.Item('OSDCOMPUTERNAME')
#    $ComputerName = $ComputerName.Trim()
#    #Write-Host $ComputerName
#}

#$ComputerTarget = $TargetPC
$ComputerName = $TargetPC

$scriptName = "ResetWorkstationAdmins"
$scriptVersion = "v1.0"
$scriptDate = "2020/07/30"
$oldVerbose = $VerbosePreference
#$VerbosePreference = "SilentlyContinue"
$VerbosePreference = "Continue"

$failedcount = 0

# Constant Variables
$Disabled = 0x0002
clear
Write-Output "====================================================="
Write-Output " $scriptName - $scriptVersion - $scriptDate          "
Write-Output "-----------------------------------------------------"
Write-Output "Initialising....."


if(!$outputdirectory) {
	$outputdirectory = (Get-Item $InputFile).directoryname
}	
$failedcomputers	=	Join-Path $outputdirectory "failed-computers.txt"
$stream = [System.IO.StreamWriter] $failedcomputers
$stream.writeline("ComputerName `t Connection `t PasswordChangeStatus")
$stream.writeline("-------------`t -----------`t --------------------")

#$password = Read-Host "Enter the password" -AsSecureString
#$confirmpassword = Read-Host "Confirm the password" -AsSecureString

$password = ConvertTo-SecureString "Secretus1519!" -AsPlainText -Force
$confirmpassword = ConvertTo-SecureString "Secretus1519!" -AsPlainText -Force

#$ComputerName = $TargetPC

#$pwd1_text = $password
#$pwd2_text = $password

$pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
$pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

if($pwd1_text -ne $pwd2_text) {
	Write-Error "Entered passwords are not same. Script is exiting"
    $stream.close()
	exit
}
<#
# Get our input data
if(!$InputFile) {
    # If no input file specified
    Write-Output "No input file specified - Using AD instead"
    # Get data from AD
    $Computers = Get-ADComputer -Filter * | Where-Object {$_.Name -like "A0*" -or $_.Name -like "D0*" -or $_.Name -like "L0*" } | Select -Property Name | Sort-Object -Property Name
    
}
Else {
    # Otherwise check if the file specified exists
    if(!(Test-Path $InputFile)) {
	    Write-Error "File ($InputFile) not found. Script is exiting"
        $stream.close()
	    exit
    }
    # and if it does use it
    $Computers = Get-Content -Path $InputFile

}
#>

# Now for each computer identified
#foreach ($Computer in $Computers) {
	#$ComputerName	=	$Computer.Name.ToUpper()
	$Isonline	=	"OFFLINE"
	$Status		=	"FAILED"
	Write-Output "Working on $ComputerName..."
    # Check it is online
	if(!(Test-Connection -ComputerName $ComputerName -count 1 -ErrorAction SilentlyContinue)) {
        # If it's not, then report it and move on
		Write-Verbose "`t$ComputerName is $Isonline"

    } else {
        # If it is the update the status and continue processing
        $Isonline = "ONLINE"
        Write-Verbose "`t$ComputerName is $Isonline" 

	    try {
            # If computer is online
            Write-Verbose "`tConnecting To $ComputerName"
            $adsi = [ADSI]"WinNT://$ComputerName"
            $existing = $adsi.Children | where {$_.SchemaClassName -eq 'user' -and $_.Name -eq $UserName }
            if ($existing -eq $null) {
                Write-Verbose "`tCreating new local user $UserName."
                $newUser = $adsi.Create("User", $UserName)
                $newUser.SetPassword($pwd1_text)
                $newUser.SetInfo()
    
                Write-Verbose "`tAdding local user $UserName to $group."
                $adminGroup = [ADSI]"WinNT://$ComputerName/Administrators,group"
                $adminUser = [ADSI]"WinNT://$ComputerName/$UserName,user"
                $adminGroup.Add($adminUser.Path)

            }
            else {
                Write-Verbose "`tSetting password for existing local user $UserName."
                $existing.SetPassword($pwd1_text)
                Write-Verbose "`tPassword Change completed successfully"
            }

            Write-Verbose "`tEnsuring password for $UserName never expires."
            & WMIC USERACCOUNT WHERE "Name='$UserName'" SET PasswordExpires=FALSE | Out-Null
		    $Status = "SUCCESS"
	    }
	    catch {
		    $Status = "FAILED"
		    Write-Verbose "`tFailed to Change the $UserName password. Error: $_"
	    }

        # If the above worked the we can disable the Administrator login
        if($Status -eq 'SUCCESS') {
            try {
            
                $adsiAdmin = [ADSI]"WinNT://$ComputerName/Administrator"
                if([boolean]($adsiAdmin.UserFlags.value -BAND $Disabled)){
                    Write-Verbose "`tAdministrator Account Already Disabled"
                } else {
                    Write-Verbose "`tAdministrator Account Disabled"
                    $adsiAdmin.userflags.value = $adsiAdmin.UserFlags.value -BOR $Disabled
                    $adsiAdmin.SetInfo()
                }
            
            }
            catch {
                $Status = "WARNING"
                Write-Verbose "`tFailed to disable Administrator account"
            }
        }
	}

	$obj = New-Object -TypeName PSObject -Property @{
 		ComputerName = $ComputerName
 		IsOnline = $Isonline
 		PasswordChangeStatus = $Status
	}

	$obj | Select ComputerName, IsOnline, PasswordChangeStatus | Out-Null
	
	if($Status -eq "FAILED" -or $Status -eq "WARNING" -or $Isonline -eq "OFFLINE") {
        $failedcount++
		$stream.writeline("$ComputerName `t $isonline `t $status")
	}
#}

$stream.close()
Write-Output "`nPlease check the file $failedcomputers for any computers that failed to be updated ($failedcount)"

$VerbosePreference = $oldVerbose
