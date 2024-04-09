##
# User login script, doing gpresult everytime while login, and save the result into log file
#
# testing machine working folder \\v00000-albert1\c$\Temp\testing_user
# 
#

# pause 60 second, waiting for the GPO applied  
$Sleep_Time = 60
#Start-Sleep -Seconds $Sleep_Time 

#remove all network drive
#NET USE * /d /y
#run gpupdate /force
#gpupdate /force

$WorkingPath = "C:\Temp"
$testing_user = Get-ChildItem -Path "$WorkingPath\testing_user" | Where-Object { !$_.PSIsContainer -and $_.Name -ne "before" -and $_.Name -ne "after" -and $_.Name -ne "done"} 


function Get-ResultToCSV {

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $WorkingPath,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $testing_user,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $status

    )

        $date = Get-Date
        Write-Host $status

        # run gprsult and export to xml file
        & gpresult /x $WorkingPath\$testing_user.xml /f

        # Import the XML file
        $results = [xml] (Get-Content $WorkingPath\$testing_user.xml)

        # Output the results
        $OU_Path = $results.Rsop.UserResults.SOM 
        $Applied_GPO = $results.Rsop.UserResults | Select -ExpandProperty GPO | Where-Object { $_.FilterAllowed -eq 'true' -and $_.Link.Enabled -eq 'true' -and $_.Link.SOMPath -ne 'local' } | Select Name | Sort-Object Name
        $Applied_GPO | ForEach-Object { [pscustomobject]@{ UserID = $testing_user ; AppliedGPO = $_.Name ; OUPath = $OU_Path ; Timestamp = $date }} | Export-Csv -Path $status -Append -NoTypeInformation -Force

        # get drive mapped
        $Drive = Get-SMBMapping
        $Drive | ForEach-Object { [pscustomobject]@{  UserID = $testing_user ; DriveLetter = $_.LocalPath + $_.RemotePath ; OUPath = $OU_Path ; Timestamp = $date }} | Export-Csv -Path $status -Append -NoTypeInformation -Force

        # get printer
        $Printer = Get-Printer | Where-Object {$_.Type -ne 'Local'} | Select Name
        $Printer | ForEach-Object { [pscustomobject]@{ UserID = $testing_user ; Printer = $_.Name ; OUPath = $OU_Path ; Timestamp = $date }} | Export-Csv -Path $status -Append -NoTypeInformation -Force
  
        #del gpupdate flag file on local
        $flag = "$env:APPDATA\MPSC\GPUPDATE.20201208"
        if (Test-Path $flag) {
            Remove-Item $flag -Force -Confirm:$false
        }

        #remove all network drive
        NET USE * /d /y


        #make done flag file
        $flag = "$WorkingPath\testing_user\done"
        if (!(Test-Path $flag)){
            New-Item -path "$WorkingPath\testing_user" -name done -type "file" -value "done"
        }


        #del user id, before and after flag file
        $flag = "$WorkingPath\testing_user\$testing_user"
        if (Test-Path $flag) {
            Remove-Item $flag -Force -Confirm:$false
        }
        $flag = "$WorkingPath\testing_user\after"
        if (Test-Path $flag) {
            Remove-Item $flag -Force -Confirm:$false
        }
        $flag = "$WorkingPath\testing_user\before"
        if (Test-Path $flag) {
            Remove-Item $flag -Force -Confirm:$false
        }


    }


if ($testing_user) {
    
    $Result_Location = "\\files\PUBLIC\Logs\GPResult"
    $GPResult_Before = "$Result_Location\GPResult_before.csv"
    $GPResult_After = "$Result_Location\GPResult_after.csv"
    
    # check the status
    #Test-Path $path -PathType Leaf
    $status = Get-ChildItem -Path "$WorkingPath\testing_user" | Where-Object { $_.Name -eq "before" -or $_.Name -eq "after" }  

    if ($status.Name -eq 'before'){
        
        Get-ResultToCSV -WorkingPath $WorkingPath -testing_user $testing_user -status $GPResult_Before

    }

    if ($status.Name -eq 'after'){

        Get-ResultToCSV -WorkingPath $WorkingPath -testing_user $testing_user -status $GPResult_After
    }

} else {

    Write-Host "No testing user"

}


#pause

<#
Start
  if not exist c:\temp\gprun.bat
    Load Next User to Test
    GPResult > GPBefore_USER.log
    Copy Security Groups
    Move OU
    Create C:\Temp\RunGP.bat GPResult > GPAfter_USER.log
  Reboot
  Login Script Calls c:\Temp\RunGP.bat
  Delete c:\temp\RunGP.bat
  Logout
#>