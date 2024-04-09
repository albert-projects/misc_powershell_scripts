$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"

Import-Module ActiveDirectory
# Import-Module ZTIUtility.psm1
Start-Sleep -Seconds 60

$SQLServer = "VWSPMSDT01"
$SQLDBName = "MDT"
$Instance = "SQLEXPRESS"
$pwd = "MDTConnect"
$table = "dbo.MDTProgress"

$type = ""

# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
# $CompName = $TSenv.Value("OSDComputername")
# $Source_OU = "CN=" + $CompName + ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"
#$Source_OU = ",OU=Test,OU=Computers,OU=MPSC,DC=mpsc,DC=nsw,DC=gov,DC=au"
$Source_OU = ",OU=MDT-PrestagedDevices,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"


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

$result = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr

foreach($row in $result)
{
    $ComputerName = $row.Item('OSDCOMPUTERNAME')
    $ComputerName = $ComputerName.Trim()
    #Write-Host $ComputerName
    $isLaptop = $row.Item('ISLAPTOP')
    $isLaptop = $isLaptop.Trim()
    $isDesktop = $row.Item('ISDESKTOP')
    $isDesktop = $isDesktop.Trim()
    $isVM = $row.Item('ISVM')
    $isVM = $isVM.Trim()
    $MacAddress = $row.Item('MACADDRESS001')
    $MacAddress = $MacAddress.Trim()


    if ($isLaptop -eq "True"){
       
      $type = ""

      $queryStr2 = "SELECT TOP (1) 
      [Create_Datetime]
      ,[COMPUTERNAME]
      ,[SERIALNUMBER]
      ,[MACADDRESS1]
      ,[MACADDRESS2]
      ,[MODEL]
      ,[TYPE]
      ,[BUNDLESOFTWARE]
      ,[ACTIVATION]
      ,[Enable]
      FROM [MDT].[dbo].[MDTApprovalList]
      WHERE MACADDRESS2='" + $MacAddress + "'
      ORDER BY Create_Datetime ASC
      ;"

      $result2 = Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $queryStr2
      
      foreach($row2 in $result2)
        {
            $type = $row2.Item('TYPE')
            $type = $type.Trim()
            Write-Host $type
        }
        if ($type -eq "Tablet"){
            $ComputerType = "TABLET"
            $Target_OU = "OU=Tablets,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
        }else{
            $ComputerType = "LAPTOP"
            $Target_OU = "OU=Laptops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
        }
    }
    if ($isDesktop -eq "True"){
        $ComputerType = "DESKTOP"
        $Target_OU = "OU=Desktops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
    }
    if ($isVM -eq "True"){
        $ComputerType = "VM"
        $Target_OU = "OU=Desktops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
    }
}

$Logfile= "\\VWSPMSDT01\MDT_Logs\" + $ComputerName + ".txt"
Start-Transcript -path $Logfile

<#
#looking for the folder
$folder = "\\VWSPMSDT01\MDT_Logs\MoveOU"

foreach($file in Get-ChildItem -Path "$folder")
{
    $FileName = $folder + "\" + $file
    $ComputerName = Get-Content "$FileName"
    #Write-Host $ComputerName
    $Source_OU = "CN=" + $ComputerName + $Source_OU
  
    #Write-Host $Source_OU
#>

#Restart-Computer -ComputerName $ComputerName -Force


$UpdateStr = "UPDATE " + $table + 
       " SET MDT_FINISH = 'N'
       WHERE OSDCOMPUTERNAME = '" + $ComputerName + "';"

Invoke-Sqlcmd  -ServerInstance $SQLServer -Username 'MDTConnect' -Password $pwd -Database $SQLDBName -Query $UpdateStr
 # write-host $UpdateStr


if($ComputerName.Length -eq 14 -or $ComputerName.Length -eq 15)
{
    $target = $ComputerName
    $Count = 0

    do{
        $Count++              
        $alive=Test-Connection -ComputerName $target -quiet
        #$alive=Test-Connection -ComputerName D05883-4MDY933 -quiet
        $alive.ToString()

        if($alive.ToString() -eq "True"){
     
            $script = $PSScriptRoot+"\ResetWorkstationAdmin.ps1"
            & $script -TargetPC $ComputerName 
            $Count = $Count + 10
        }
          
        Start-Sleep -Seconds 60         
        
     } while ($Count -le 10)


     Restart-Computer -ComputerName $ComputerName -Force

     $Source_OU = "CN=" + $ComputerName + $Source_OU
     $c = Get-ADComputer $ComputerName

    if($c -ne $null) { 
        Move-ADObject -Identity $Source_OU -TargetPath $Target_OU

        if($ComputerType -eq "LAPTOP" -or $type -eq "Tablet")
        {
            $member = "CN=" + $ComputerName + "," + $Target_OU
            #Add-ADGroupMember -Identity "Security-Access-Wifi-Corporate" -Members "CN=VM-005056A1D954,OU=Desktops,OU=Production,OU=MPSC Computers,DC=mpsc,DC=nsw,DC=gov,DC=au"
            Add-ADGroupMember -Identity "Security-Access-Wifi-Corporate" -Members $member
        }

    } 
#}


    Start-Sleep -Seconds 60

    $Stoploop = "false"
    $Retrycount = 0

    do {
        try {
            Restart-Computer -ComputerName $ComputerName -Force -ErrorAction Stop
            Write-Host "restarted"
            $Stoploop = "true"
        }
        catch {
            if ($Retrycount -gt 3){
                Write-Host "restart failed"
                $Stoploop = "true"
            }
            else {
                Start-Sleep -Seconds 60
                $Retrycount++
                }
        }
    }While ($Stoploop -eq "false")

   
    #Start-Sleep -Seconds 120
    #Start-Sleep -Seconds 60

    $script = $PSScriptRoot+"\PDQDeploy41015.ps1"
    & $script -TargetPC $ComputerName 
}

if($ComputerName.Length -eq 12)
{
    Start-Sleep -Seconds 300

    #$ComputerName = "L02220-6XXV9H2"
    #$MacAddress = "A4:4C:C8:22:10:4A"

    Write-Host "In-place Upgrade"
    #$script = "C:\CustomScript\PDQDeployInPlaceUpgradeFollowUp.ps1"
    $script = $PSScriptRoot+"\PDQDeployInPlaceUpgradeFollowUp.ps1"
    & $script -TargetPC $ComputerName -MacAddress $MacAddress

}

Stop-Transcript

#Restart-Computer -ComputerName $ComputerName -Force
#Start-Sleep -Seconds 60

#$message = "C:\windows\system32\msg.exe * Finished the MDT process on " + $ComputerName 
#Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $message -ComputerName $ComputerName


#"ABC test" | Out-File \\D05886-4MDV933\c$\log.txt -append
#$message = "C:\windows\system32\msg.exe * Finished the MDT process on " + $ComputerName 
#Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $message -ComputerName D05886-4MDV933

#$ComputerName = "D05886-4MDV933"
#Invoke-Expression "&'C:\CustomScript\PDQDeploy.ps1' $ComputerName MPSC_Standard_Build_Software"
