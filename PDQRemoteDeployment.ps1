# Design for use powershell GUI interface for PDQ deployment, the powershell communication with PDQ server and DB (vwspmsdt01)
# using PDQ api, if pdq have some major update, it might need to modify the powershell command
#
# the powershell will looking for all of the pdq package start with "R-" prefix
# application list for computer shows the current application record in PDQ invertory, it might not up-to-date, depends on the last scanning date 
#
# Version 1.0 on 10/09/2021
# need to load with WpfAnimatedGif.dll for handle gif
# DeploymentLog.json for save the deployment log
# 
# -------------------------------------------------------

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationProvider
Add-Type -AssemblyName PresentationCore   

# Set credential to MPSC\PDQ user for vwspmsdt01
$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Your Secret Password" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred
$sess2 = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred
$global:sess3 = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

# PDQ execution path
$Exe_inventory = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\"
$Exe_deploy = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

# PDQ SQL Lite database file path
$Inventory_db = "C:\ProgramData\Admin Arsenal\PDQ Inventory\Database.db"
$Deploy_db = "C:\ProgramData\Admin Arsenal\PDQ Deploy\Database.db"

#log file
$jsonfile = "DeploymentLog.json"
#$jsonfile = "C:\Users\akwan\Documents\DeploymentLog.json"
#$global:DeploymentUser = $env:UserName
#$global:DeploymentMachine = $env:ComputerName


$global:BeforeDeployID = ""
$global:objListComp = ""
$global:ListComp = ""
$global:Deploying = ""
$global:objPDQPackage = ""
$global:ListPDQPackage = ""
$global:ListingApps = ""
$global:objListingApps = ""
$global:objDeploySoftware = ""
$global:Offline = ""

$global:Exe_deploy2 = ""
$global:ComputerTarget = ""
$global:Deploy_db2 = ""
$global:ComputerTarget2 = ""
$global:SaveLog = ""


function DisableButton{

    $btnDeploy.IsEnabled = $False
    $btnSelect.IsEnabled = $False
    $cmbAvailablePackage.IsEnabled = $False
    $cmbCompName.IsEnabled = $False
    $txtRemark.IsEnabled = $False

}

function EnableButton{
    
    $btnDeploy.IsEnabled = $True
    $btnSelect.IsEnabled = $True
    $cmbAvailablePackage.IsEnabled = $True
    $cmbCompName.IsEnabled = $True
    $txtRemark.IsEnabled = $True

}

function ResetForm{

    $btnDeploy.IsEnabled = $False
    $cmbAvailablePackage.IsEnabled = $True

    $datDeployStatus.ItemsSource = $null
    $datDeployStatus.Items.Refresh()
    $datDeployStatus.Items.Clear()

    $dgInstalledSW.ItemsSource = $null
    $dgInstalledSW.Items.Refresh()
    $dgInstalledSW.Items.Clear()

}

function SaveJson{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $configfile,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $DeployTo,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $DeploySoftware,
         [Parameter(Mandatory=$true, Position=3)]
         [string] $DeployId
    )
    $json = Get-Content $configfile -raw | ConvertFrom-Json
    #Write-Host $json.Deploy
    #Write-Host $configfile
    $TimeNow = Get-Date -format "yyyy-MM-dd HH:mm:ss"  
    
    $tempjson = $json.Deploy
    #Write-Host $tempjson
    #$txtRemark.Text  
    $tempjson2 = [pscustomobject]@{DeployBy=$env:UserName;DeployFrom=$env:ComputerName;DeployTo=$DeployTo;DeploySoftware=$DeploySoftware;DeployTime=$TimeNow;DeployId=$DeployId;DeployResult='';EndTime='';Remark=$txtRemark.Text}
    #Write-Host $tempjson2
    $tempjson += $tempjson2
    
    $NewJson = New-Object PSObject
    $NewJson | Add-Member -MemberType NoteProperty -Name "Deploy" -Value @($tempjson) 
    $NewJson | ConvertTo-Json -depth 100 | Out-File $configfile


}

function UpdateJson{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $configfile,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $DeployId,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $DeployResult
    )

    $json = Get-Content $configfile -raw | ConvertFrom-Json
    $TimeNow = Get-Date -format "yyyy-MM-dd HH:mm:ss"  

    $json.Deploy  | % { 
        if($_.DeployId -eq $DeployId){

            $_.EndTime = $TimeNow
            $_.DeployResult = $DeployResult
        }
    }
    $json | ConvertTo-Json -depth 100 | set-content $configfile 

}

function LoadJson{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $configfile
    )

    #$lblMsg.Content = ""

    $datLog.Clear()
    #$datLog.CommitEdit()
    #$datLog.Items.Refresh()
    $json = Get-Content $configfile -raw | ConvertFrom-Json
    #$datGrid.ItemsSource = $json.staff
    #$datGrid.Columns[4].Visibility = "Collapsed"
    #$datGrid.DataContext    

    $datLog.ItemsSource = $json.Deploy
    #$datGrid.AddChild([pscustomobject]@{EffectiveDate='a';Role='b'})
    #$json.Deploy | ForEach-Object {
    #    #Write-Host $_.DeployId      
    #    $datLog.AddChild([pscustomobject]@{DeployId=$_.DeployId;DeployBy=$_.DeployBy;DeployFrom=$_.DeployFrom;DeployTo=$_.DeployTo;DeploySoftware=$_.DeploySoftware;DeployTime=$_.DeployTime;EndTime=$_.EndTime;DeployResult=$_.DeployResult;Remark=$_.Remark})
    #}          
    #$datLog.CommitEdit()
    #$datLog.Items.Refresh()
}


function DTimer{

    #Write-Host "Timer"

    #for ($i = 0; $i -lt 10; $i++)
    #{
    #    Start-Sleep -Milliseconds 200
    #    [System.Windows.Forms.Application]::DoEvents()
    #}

        $btnSelect.IsEnabled = $True
        $cmbAvailablePackage.IsEnabled = $True
        $cmbCompName.IsEnabled = $True

        # check job is completed
        if ($global:ListComp -ne "Done"){
           
            #$cmbCompName.SelectedItem = $null
            #$cmbCompName.ItemsSource = $null
            #$cmbCompName.SelectedItem = $null
            #$cmbCompName.Items.Clear()

            $jobName = $global:objListComp.Name
            #$jobState = (Wait-Job -Name $jobName).State
            $jobState = $global:objListComp.State
            #Write-Host "ListComp " $global:objListComp.State
            #write-host "Checking status of $jobName..."
            #sleep -seconds 1
            #for ($i = 0; $i -lt 5; $i++)
            #{
            #    Start-Sleep -Milliseconds 200
            #    [System.Windows.Forms.Application]::DoEvents()
            #}
            if ($jobState -eq "Completed"){
                #write-host "$jobName completed."
                $cmbCompName.Items.Clear()
                        
                $resultJob = receive-job $global:objListComp.Id
                $Form.Resources.Add("ComputerList", $resultJob)
                               
                $global:ListComp = "Done"
            }
            if ($jobState -eq "NotStarted" -or $jobState -eq "Failed" -or $jobState -eq "Stopped" -or $jobState -eq "Blocked" -or $jobState -eq "Suspended" -or $jobState -eq "Disconnected" ){
                
                $global:ListComp = "Done"

                $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
                $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Error
                $MessageBody = "An error occurred with PDQ server`nPlease close the Powershell program and re-run again`nIf the error still exist, please contact IT Dept."
                $MessageTitle = "An error occurred with PDQ server"

                [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
                
            }

        #$ComputerList 
        }
        
        if($global:ListPDQPackage -ne "Done"){          
            

            $jobName = $global:objPDQPackage.Name
            #$jobState = (Wait-Job -Name $jobName).State
            $jobState = $global:objPDQPackage.State
            
            #Write-Host "ListPDQPackage " $global:objPDQPackage.State

            if ($jobState -eq "Completed"){
                #write-host $PackageList
                $cmbAvailablePackage.Items.Clear()

                $DeployPackageItem =  @()

                $resultJob = receive-job $global:objPDQPackage.Id
                $resultJob | ForEach-Object {

                    $Object = New-Object PSObject
                    $Object | add-member Noteproperty PackageName $_

                    #write-host $Object 
                    $DeployPackageItem += $Object
                }

                $ObjAvailablePackage = $DeployPackageItem | Where-Object {$_.PackageName -match '^R-' } | select PackageName
                #write-host $ObjAvailablePackage

                $ObjAvailablePackage | ForEach-Object {$_.PackageName = $_.PackageName.substring(2,$_.PackageName.length-2) }
                $Form.Resources.Add("AvailablePackage", $ObjAvailablePackage.PackageName)    

                $global:ListPDQPackage = "Done"
            }
            if ($jobState -eq "NotStarted" -or $jobState -eq "Failed" -or $jobState -eq "Stopped" -or $jobState -eq "Blocked" -or $jobState -eq "Suspended" -or $jobState -eq "Disconnected" ){
                
                $global:ListPDQPackage = "Done"

                $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
                $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Error
                $MessageBody = "An error occurred with PDQ server`nPlease close the Powershell program and re-run again`nIf the error still exist, please contact IT Dept."
                $MessageTitle = "An error occurred with PDQ server"

                [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
                
            }    
        
        }       

        if ($global:Deploying -eq "Deploying" -and $global:Offline -ne "Offline"){

            #if ($DeployProgress.DeploymentId -ne $null){
            #    $global:BeforeDeployID = $DeployProgress.DeploymentId.ToString()
            #    #Write-Host $BeforeDeployID
            #} 

            DeployStatus -sess $global:sess3 -Exe_Location $global:Exe_deploy2 -target $global:ComputerTarget -deploy_db $global:Deploy_db2

        }

        if($global:ListingApps -eq "Listing"){
        
            $jobName = $global:objListingApps.Name
            #$jobState = (Wait-Job -Name $jobName).State
            $jobState = $global:objListingApps.State

            #Write-Host $jobState
            if ($jobState -eq "Completed"){
                
                #Write-Host $jobState      
                #Write-Host $global:objListingApps
                #Write-Host $global:objListingApps.ToString()                    
                $resultJob = receive-job $global:objListingApps.Id
                #Write-Host $resultJob

                $imgLoading3.Visibility = "Hidden"

                $resultJob | ForEach-Object{
                
                    if ($_.AI -eq $null){
                        $_.AI = $_.AI2          
                    }            
                }

                $dgInstalledSW.ItemsSource = $resultJob | Sort-Object AN  

                $ScanDate = $resultJob | Select-Object -ExpandProperty CS -Last 1
                $lblScanDate.Content = "Scanned Date: " + $ScanDate

                #$dgInstalledSW.AddChild([pscustomobject]@{ComputerName='a';ApplicationName='b'})

                $ComputerTarget = $global:ComputerTarget2
                # check the target pc online or not
                $alive=Test-Connection -ComputerName $ComputerTarget -Count 1 -quiet
                #$alive=Test-Connection -ComputerName D05883-4MDY933 -quiet
                $alive.ToString()

                if($alive.ToString() -eq "True"){

                    $lblCompStatus.Content = $ComputerTarget + " is online."

                }else{
    
                    $lblCompStatus.Content = $ComputerTarget + " is offline, couldn't do the deployment"
                }

                $global:ListingApps = "Done"
                $cmbCompName.IsEnabled = $True
                $btnSelect.IsEnabled = $True
                $btnDeploy.IsEnabled = $True
                $txtRemark.IsEnabled = $True

            }

            if ($jobState -eq "NotStarted" -or $jobState -eq "Failed" -or $jobState -eq "Stopped" -or $jobState -eq "Blocked" -or $jobState -eq "Suspended" -or $jobState -eq "Disconnected" ){
                
                $global:ListingApps = "Done"

                $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
                $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Error
                $MessageBody = "An error occurred with PDQ server`nPlease close the Powershell program and re-run again`nIf the error still exist, please contact IT Dept."
                $MessageTitle = "An error occurred with PDQ server"

                [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
                
            }  

        }
                
}


function Get-ComputerList{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [Object[]] $sess,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Exe_Location,
         [Parameter(Mandatory=$false, Position=2)]
         [string] $computer,
         [Parameter(Mandatory=$false, Position=3)]
         [string] $target

    )

    
    $ComputerList = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $computer, $target -AsJob -ScriptBlock {

        param($Exe_Location, $computer, $target)

        Set-Location -Path $Exe_Location;
        $lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
        #Write-Host $lastexitcode
        Return $lastexitcode
    }
    
    Return $ComputerList

    <#
    $resultJob = Receive-Job -id $ComputerList.Id
    Write-Host  $ComputerList.State
    Write-Host  $ComputerList.Id
    Write-Host  $resultJob 

    # Wait until job is completed
    do{
        $jobName=$ComputerList.Name
        $jobState = (Wait-Job -Name $jobName).State
        write-host "Checking status of $jobName..."
        #sleep -seconds 1
        for ($i = 0; $i -lt 5; $i++)
        {
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.Application]::DoEvents()
        }
        if ($jobState -eq "Completed"){write-host "$jobName completed."}
    } until ($jobState -eq "Completed")    

    $result = receive-job $ComputerList.Id

    $Form.Resources.Add("ComputerList", $result)  
    #$ComputerList 
    #>
}



function DeployStatus{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [Object[]] $sess,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Exe_Location,
         [Parameter(Mandatory=$false, Position=2)]
         [string] $package,
         [Parameter(Mandatory=$false, Position=3)]
         [string] $target,
         [Parameter(Mandatory=$false, Position=4)]
         [string] $deploy_db

    )

        #Do{
        $stop_ind = 0

        # set the refresh timer
        #Start-Sleep -s 3
        #for ($i = 0; $i -lt 10; $i++)
        #{
        #    Start-Sleep -Milliseconds 200
        #    [System.Windows.Forms.Application]::DoEvents()
        #}

        # clear the datagrid 
        $datDeployStatus.ItemsSource = $null
        $datDeployStatus.Items.Refresh()
        $datDeployStatus.Items.Clear()

        $itemArray = @()

        # retrieve the data from database
        # for target pc and overall status
        $Query = "SELECT DeploymentComputers.DeploymentComputerId, DeploymentComputers.ShortName, DeploymentComputers.Error, DeploymentComputers.Started, DeploymentComputers.DeploymentId, DeploymentComputers.Status from DeploymentComputers
                  left join DeploymentComputerSteps 
                  on DeploymentComputers.DeploymentId = DeploymentComputerSteps.DeploymentComputerId
                  where shortname = '" + $target + "' order by DeploymentComputers.started desc limit 1;"


        $DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $deploy_db, $Query -ScriptBlock {

            param($Exe_Location, $Database, $Query)

            Set-Location -Path $Exe_Location;
            $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
            #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
            #Write-Host $result
            Return $result
        }

        #$datDeployStatus.AddChild([pscustomobject]@{DeploymentID='a';DeployTarget='b';DeployStatus='c';DeploySteps='d';DeployError='e';ReturnCode='g';DeployStarted='f'})

        if ($DeployProgress.DeploymentComputerId -ne $null){
            $tempDeploymentComputerId = $DeployProgress.DeploymentComputerId.ToString()
        }
        if ($DeployProgress.ShortName -ne $null){
            $tempShortName = $DeployProgress.ShortName.ToString()
        }
        if ($DeployProgress.Error -ne $null){
            $tempError = $DeployProgress.Error.ToString()
        }
        if ($DeployProgress.Started -ne $null){
            $tempStarted = $DeployProgress.Started.ToString()
            $tempStarted2 = $tempStarted
        }
        if ($DeployProgress.DeploymentId -ne $null){
            $tempDeploymentId = $DeployProgress.DeploymentId.ToString()
            #Write-Host $global:BeforeDeployID $tempDeploymentId
            #$lblDeployStatus.Content = $tempDeploymentId
        }
        if ($DeployProgress.Status -ne $null){
            $tempStatus = $DeployProgress.Status.ToString()
            $tempStatus2 = $tempStatus
            #$lblDeployStatus.Content= $tempStatus
        }
        if ($cmbAvailablePackage.SelectedItem -ne $null){
            $DeployPackage = $cmbAvailablePackage.SelectedItem.ToString()
        }

        if ($global:BeforeDeployID -ne $tempDeploymentId){

            $itemArray += ([pscustomobject]@{DeploymentID=$tempDeploymentId;DeployTarget=$tempShortName;DeployStatus=$tempStatus;DeploySteps=$DeployPackage;DeployError=$tempError;ReturnCode='';DeployStarted=$tempStarted})           
            #Write-Host $itemArray
            #$datDeployStatus.AddChild([psc$datDeployStatus.Items.Refresh()ustomobject]@{DeploymentID=$tempDeploymentId;DeployTarget=$tempShortName;DeployStatus=$tempStatus;DeploySteps=$DeployPackage;DeployError=$tempError;ReturnCode='';DeployStarted=$tempStarted})
            $datDeployStatus.ItemsSource = $itemArray

            $lblDeployStatus.Content= "Deployment Status: " + $tempStatus

            if ($global:SaveLog -eq 1){
                #write json log file

                SaveJson -configfile $jsonfile -DeployTo $tempShortName -DeploySoftware $cmbAvailablePackage.SelectedItem.ToString() -DeployID $tempDeploymentId
                LoadJson -configfile $jsonfile
                $global:SaveLog = 0
            }

        }

        # for all other steps in the package
        $Query = "SELECT Number, Title, ReturnCode, Error, Started from DeploymentComputerSteps
	              WHERE DeploymentComputerId = (select DeploymentComputerId from 
			             DeploymentComputers where shortname = '" + $target + "' order by started desc limit 1)
	              AND Note <> 'Step is disabled';"

        $DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $deploy_db, $Query -ScriptBlock {

            param($Exe_Location, $Database, $Query)

            Set-Location -Path $Exe_Location;
            $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
            #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
            #Write-Host $result
            Return $result
        }
         <#
         do{
            $jobName = $DeployProgress.Name
            $jobState = (Wait-Job -Name $jobName).State
            #write-host "Checking status of $jobName..."
            #sleep -seconds 1
            for ($i = 0; $i -lt 5; $i++)
            {
                Start-Sleep -Milliseconds 200
                [System.Windows.Forms.Application]::DoEvents()
            }
            if ($jobState -eq "Completed"){
                #write-host "$jobName completed."
                #$global:ListComp = "Completed"
            }
        } until ($jobState -eq "Completed")    

        $DeployProgress = receive-job $DeployProgress.Id
        #>

        $ind = 0
        $DeployProgress | ForEach-Object {

            $ind ++
            $tempNumber = ""
            $tempReturnCode = ""
            $tempStarted = ""
            $tempTitle = ""
            $tempError = ""
            $tempStatus = ""
            $tempSteps = ""

            #write-host $DeployProgress.Count

            if ($_.Number -ne $null){
                $tempNumber = $_.Number.ToString()          
            }
            if ($_.ReturnCode -ne $null){
                $tempReturnCode = $_.ReturnCode.ToString()
                #write-host $_.ReturnCode.ToString()
            }
            if ($_.Started -ne $null){
                $tempStarted = $_.Started.ToString()
                $StepStarted = [datetime]::parseexact($tempStarted2, 'yyyy-MM-dd HH:mm:ss', $null)
                $TimeNow = Get-Date -format "yyyy-MM-dd HH:mm:ss"
                $diff= New-TimeSpan -Start $StepStarted -End $TimeNow

            }
            if ($_.Title -ne $null){
                $tempTitle = $_.Title.ToString()
            }
            if ($_.Error -ne $null){
                $tempError = $_.Error.ToString()
                $xml = [xml]$tempError
                $tempError = $xml.Error.Message

            }
            if ($ind -eq $DeployProgress.Count){
                $tempStatus = $tempStatus2
                $tempError = "Run time: " + $diff
            }
            if (($ind -lt $DeployProgress.Count) -or ($tempStatus2 -eq "Successful") ){
                $tempStatus = "done" 
            }

            $tempSteps = $tempNumber + " - " + $tempTitle

            if ($global:BeforeDeployID -ne $tempDeploymentId){
                
                $datDeployStatus.ItemsSource = $null
                $datDeployStatus.Items.Refresh()
                $datDeployStatus.Items.Clear()

                $itemArray += ([pscustomobject]@{DeploymentID='';DeployTarget='';DeployStatus=$tempStatus;DeploySteps=$tempSteps;DeployError=$tempError;ReturnCode=$tempReturnCode;DeployStarted=$tempStarted})              
                #Write-Host $itemArray
                $datDeployStatus.ItemsSource = $itemArray

                #$datDeployStatus.AddChild([pscustomobject]@{DeploymentID='';DeployTarget='';DeployStatus=$tempStatus;DeploySteps=$tempSteps;DeployError=$tempError;ReturnCode=$tempReturnCode;DeployStarted=$tempStarted})
                #$datDeployStatus.SelectedIndex = $datDeployStatus.Items.Count - 1;
                $datDeployStatus.UpdateLayout()
                $datDeployStatus.ScrollIntoView($datDeployStatus.Items[$datDeployStatus.Items.Count - 1])
                $datDeployStatus.UpdateLayout()
            
            }
            #$datDeployStatus.Items.Refresh()
            #$datDeployStatus.UpdateLayout()
            #$datDeployStatus.ItemsSource = $itemArray

            #$datDeployStatus.AddChild([pscustomobject]@{DeploymentID='a';DeployTarget='b';DeployStatus='c';DeploySteps='d';DeployError='e';ReturnCode='g';DeployStarted='f'})
            #$tempObj = [pscustomobject]@{DeploymentID='a';DeployTarget='b';DeployStatus='c';DeploySteps='d';DeployError='e';ReturnCode='g';DeployStarted='f'}
            #$datDeployStatus.ItemsSource = $tempObj



        }
        if((($tempStatus2 -eq "Successful") -or ($tempStatus2 -eq "Failed")) -and ($global:BeforeDeployID -ne $tempDeploymentId)){
        
            $stop_ind = 1
            $global:Deploying = "Done"     
            $imgLoading.Visibility = "Hidden"

            UpdateJson -configfile $jsonfile -DeployID $tempDeploymentId -DeployResult $tempStatus2
            LoadJson -configfile $jsonfile

            $msg = $cmbAvailablePackage.SelectedItem.ToString() + " has been deployed to " + $cmbCompName.SelectedItem.ToString() + "`nPDQ inventory is updating " + $cmbCompName.SelectedItem.ToString() + "'s application list.`nPlease go back have a check later."

            $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
            $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Information
            $MessageBody = $msg
            $MessageTitle = "Done"

            [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)   

            EnableButton
        }

        #write-host $stop_ind
        #Return $stop_ind

    #} Until ((($tempStatus2 -eq "Successful") -or ($tempStatus2 -eq "Failed")) -and ($global:BeforeDeployID -ne $tempDeploymentId))

    #show finish msg
    
}



function DeploySoftware{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [Object[]] $sess,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Exe_Location,
         [Parameter(Mandatory=$false, Position=2)]
         [string] $package,
         [Parameter(Mandatory=$false, Position=3)]
         [string] $target,
         [Parameter(Mandatory=$false, Position=4)]
         [string] $deploy_db

    )

        # check again the target pc online or not
        $ComputerTarget = $cmbCompName.SelectedItem.ToString()
        $alive=Test-Connection -ComputerName $ComputerTarget -Count 1 -quiet
        $alive.ToString()

        #Write-Host = $ComputerTarget
        #Write-Host = $alive

        if($alive.ToString() -eq "True"){

            $lblCompStatus.Content = $target + " is online."

            $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
            $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Information
            $MessageBody = "This program only support single thread deployment`nPlease wait until the process done."
            $MessageTitle = "Deployment"

            [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)


            # get latest deployment id 
            $Query = "SELECT DeploymentComputers.DeploymentComputerId, DeploymentComputers.ShortName, DeploymentComputers.Error, DeploymentComputers.Started, DeploymentComputers.DeploymentId, DeploymentComputers.Status from DeploymentComputers
                  left join DeploymentComputerSteps 
                  on DeploymentComputers.DeploymentId = DeploymentComputerSteps.DeploymentComputerId
                  where shortname = '" + $target + "' order by DeploymentComputers.started desc limit 1;"


            $DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $deploy_db, $Query -ScriptBlock {

                param($Exe_Location, $Database, $Query)

                    Set-Location -Path $Exe_Location;
                    $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
                    #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
                    #Write-Host $result
                    Return $result
            }

            if ($DeployProgress.DeploymentId -ne $null){
                $global:BeforeDeployID = $DeployProgress.DeploymentId.ToString()
                #Write-Host $BeforeDeployID
            }          

            $global:SaveLog = 1
            $imgLoading.Visibility = "Visible"

            #$ComputerList = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $package, $target -ScriptBlock {
            $DeployingSoftware = Invoke-Command -Session $sess2 -ArgumentList $Exe_Location, $package, $target -Asjob -ScriptBlock {

            param($Exe_Location, $package, $target)

                Set-Location -Path $Exe_Location;
                $lastexitcode = PDQDeploy.exe Deploy -Package $package -Targets $target;
                #Write-Host $lastexitcode
                Return $lastexitcode
            } 

            # update status datagrid
            #DeployStatus -sess $sess -Exe_Location $Exe_deploy -target $ComputerTarget -deploy_db $Deploy_db
            #return $BeforeDeployID


        }else{
    
            $lblCompStatus.Content = $target + " is offline, couldn't do the deployment"
            $global:Offline  = "Offline"

            $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
            $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
            $MessageBody = $target +  " is offline, couldn't do the deployment."
            $MessageTitle = "Target PC is offline"

            [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        }

        Return $DeployProgress
        # update status datagrid
        #DeployStatus -sess $sess -Exe_Location $Exe_deploy -target $ComputerTarget -deploy_db $Deploy_db

}


function ListCompApps{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [Object[]] $sess,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Exe_Location,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $Inv_db,
         [Parameter(Mandatory=$false, Position=3)]
         [string] $computer,
         [Parameter(Mandatory=$false, Position=4)]
         [string] $target

    )
    
    # clear the datagrid 
    $dgInstalledSW.ItemsSource = $null
    $dgInstalledSW.Items.Refresh()
    $dgInstalledSW.Items.Clear()


    $global:ComputerTarget2 = $cmbCompName.SelectedItem.ToString()
    $ComputerTarget = $cmbCompName.SelectedItem.ToString()

    $Query = "select Computers.Name as CN, Applications.Name as AN, Applications.Version as AV, Applications.InstallDate as AI, Applications.InstallDateSecondary as AI2, Computers.SuccessfulScanDate as CS
          from computers, Applications
          where computers.ComputerId = Applications.ComputerId
          and Computers.Name = '" + $ComputerTarget + "'
          order by Applications.Name"

    #Write-Host $Comp
    $AppsList = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $Inv_db, $Query -AsJob -ScriptBlock {

        param($Exe_Location, $Database, $Query)

        Set-Location -Path $Exe_Location;
        $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
        #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
        #Write-Host $result
        Return $result
    }
    
    Return $AppsList

    <#
    #Write-Host $AppsList
    $dgInstalledSW.ItemsSource = $AppsList | Sort-Object AN  

    $ScanDate = $AppsList | Select-Object -ExpandProperty CS -Last 1
    $lblScanDate.Content = "Scanned Date: " + $ScanDate

    #$dgInstalledSW.AddChild([pscustomobject]@{ComputerName='a';ApplicationName='b'})

    # check the target pc online or not
    $alive=Test-Connection -ComputerName $ComputerTarget -Count 1 -quiet
    #$alive=Test-Connection -ComputerName D05883-4MDY933 -quiet
    $alive.ToString()

    if($alive.ToString() -eq "True"){

        $lblCompStatus.Content = $ComputerTarget + " is online."

    }else{
    
        $lblCompStatus.Content = $ComputerTarget + " is offline, couldn't do the deployment"
    }
    #>
    
}

function Get-PDQPackage{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [Object[]] $sess,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Exe_Location,
         [Parameter(Mandatory=$false, Position=2)]
         [string] $computer,
         [Parameter(Mandatory=$false, Position=3)]
         [string] $target

    )

    #$dgInstalledSW.Clear()
    #$AvailablePackage.Resources.Clear()

    #write-host $cmbAvailablePackage.Items.Count

    #if ($cmbAvailablePackage.Items.Count -eq 0){

        $PackageList = Invoke-Command -Session $sess -ArgumentList $Exe_Location, $package, $target -AsJob -ScriptBlock {

            param($Exe_Location, $package, $target)
            #Write-Host $Exe_Location
            Set-Location -Path $Exe_Location;
            $lastexitcode = PDQDeploy.exe GetPackageNames;
            Return $lastexitcode
 
        }

        Return $PackageList

        <#
        #write-host $PackageList
        $DeployPackageItem =  @()
        $PackageList| ForEach-Object {

            $Object = New-Object PSObject
            $Object | add-member Noteproperty PackageName $_

            #write-host $Object 
            $DeployPackageItem += $Object
        }

        $ObjAvailablePackage = $DeployPackageItem | Where-Object {$_.PackageName -match '^R-' } | select PackageName
        #write-host $ObjAvailablePackage

        $ObjAvailablePackage | ForEach-Object {$_.PackageName = $_.PackageName.substring(2,$_.PackageName.length-2) }
        $Form.Resources.Add("AvailablePackage", $ObjAvailablePackage.PackageName)  
        #>
    #}

}



# Powershell XAML GUI interface
#
[void][System.Reflection.Assembly]::LoadWithPartialName('PDQRemoteDeployment')
[void][System.Reflection.Assembly]::LoadFrom('WpfAnimatedGif.dll') 
[void][System.Reflection.Assembly]::LoadWithPartialName("UIAutomationClient")
[void][System.Reflection.Assembly]::LoadWithPartialName("UIAutomationTypes")
[void][System.Reflection.Assembly]::LoadWithPartialName("UIAutomationProvider")
[void][System.Reflection.Assembly]::LoadWithPartialName("UIAutomationClientsideProviders")
[xml]$XAML = @"

<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:gif="http://wpfanimatedgif.codeplex.com"
        Title="PDQ Remote Deployment" Height="768" Width="1200">
    <Grid Margin="0,0,0,0">

        <Image Name="imgIcon" HorizontalAlignment="Left" Height="100" Margin="39,10,0,0" VerticalAlignment="Top" Width="100" Source="\\files\kits$\Styles\MPSC_Logo_Web_150x150.png"/>
        <Label Name="lblTitel" Content="PDQ Remote Deployment" HorizontalAlignment="Left" Margin="158,0,0,0" VerticalAlignment="Top" FontSize="20" FontWeight="Bold"/>
        <Label Name="lblCompName" Content="Computer Name" HorizontalAlignment="Left" Height="27" Margin="162,43,0,0" VerticalAlignment="Top" Width="114"/>
        <ComboBox Name="cmbCompName" HorizontalAlignment="Left" Height="27" Margin="281,43,0,0" VerticalAlignment="Top" Width="209"
              SelectedItem="{Binding Path=ComputerList, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"
              ItemsSource="{DynamicResource ComputerList}"
              Text="{Binding Path=ComputerList, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"                   
        />
        <Button Name="btnSelect" Content="Select" HorizontalAlignment="Left" Height="27" Margin="512,43,0,0" VerticalAlignment="Top" Width="81"/>
        <Label Name="lblCompStatus" Content="" HorizontalAlignment="Left" Height="29" Margin="281,102,0,0" VerticalAlignment="Top" Width="312"/>       
        <Label Name="lblScanDate" Content="" HorizontalAlignment="Left" Height="29"  Margin="281,75,0,0" VerticalAlignment="Top" Width="312"/>  
        <!--
        <Button Name="btnDebug" Content="Debug" HorizontalAlignment="Left" Height="27" Margin="1050,42,0,0" VerticalAlignment="Top" Width="81"/>           
        <Button Name="btnRefresh" Content="Refresh" HorizontalAlignment="Left" Height="26" Margin="947,84,0,0" VerticalAlignment="Top" Width="81"/>
        <Button Name="btnTimer" Content="Timer" HorizontalAlignment="Left" Height="26" Margin="1050,90,0,0" VerticalAlignment="Top" Width="81"/>
        -->
        <TabControl Margin="10,101,20,27">
            <TabControl.Resources>
                <Style TargetType="TabPanel">
                    <Setter Property="HorizontalAlignment" Value="Right"/>
                </Style>
            </TabControl.Resources>
            <TabItem Header="  Deployment  ">
                <Grid Background="White">

        <DataGrid Name="dgInstalledSW" AutoGenerateColumns="False" CanUserSortColumns="True" HorizontalAlignment="Left" Height="320" Margin="10,10,0,0" VerticalAlignment="Top" Width="1130">
            <DataGrid.Columns>
                 <DataGridTemplateColumn Header="ComputerName" Width="120">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding CN, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

                 <DataGridTemplateColumn Header="ApplicationName" Width="400">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding AN, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

                 <DataGridTemplateColumn Header="Version" Width="150">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding AV, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>
                 
                 <DataGridTemplateColumn Header="InstalledDate" Width="150">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding AI, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>


            </DataGrid.Columns> 
        </DataGrid>
        
        <Label Name="lblDeployPackage" Content="Available Deploy Package" HorizontalAlignment="Left" Height="27" Margin="10,346,0,0" VerticalAlignment="Top" Width="177"/>
        <ComboBox Name="cmbAvailablePackage" HorizontalAlignment="Left" Height="27" Margin="10,378,0,0" VerticalAlignment="Top" Width="350"
              SelectedItem="{Binding Path=AvailablePackage, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"
              ItemsSource="{DynamicResource AvailablePackage}"
              Text="{Binding Path=AvailablePackage, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"                        
        />
        <DataGrid Name="datDeployStatus" AutoGenerateColumns="False" HorizontalAlignment="Left" Height="142" Margin="10,423,0,0" VerticalAlignment="Top" Width="1130" CanUserSortColumns="True">
             <DataGrid.Columns>
                  <DataGridTemplateColumn Header="DeploymentID" Width="90">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding DeploymentID, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

                 <DataGridTemplateColumn Header="Target" Width="120">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding DeployTarget, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

                 <DataGridTemplateColumn Header="Started" Width="120">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding DeployStarted, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

                 <DataGridTemplateColumn Header="Status" Width="120">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding DeployStatus, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>
                 <!--
                 <DataGridTemplateColumn Header="" Width="10">
                    <DataGridTemplateColumn.CellTemplate>                          
                        <DataTemplate> 
                            <Image Name="imgLoading1" Width="80" gif:ImageBehavior.AnimatedSource="\\files\kits$\Styles\Loading1.gif" HorizontalAlignment="Center" VerticalAlignment="Center"/> 
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>
                 -->
                 <DataGridTemplateColumn Header="Steps" Width="280">
                    <DataGridTemplateColumn.CellTemplate>                          
                        <DataTemplate> 
                            <TextBox Text="{Binding DeploySteps, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

                 <DataGridTemplateColumn Header="RunTime / Error" Width="280">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding DeployError, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

                 <DataGridTemplateColumn Header="ReturnCode" Width="80">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <TextBox Text="{Binding ReturnCode, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True"/>  
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                 </DataGridTemplateColumn>

             </DataGrid.Columns>
        </DataGrid>
        <Button Name="btnDeploy" Content="Deploy" HorizontalAlignment="Left" Height="27" Margin="386,378,0,0" VerticalAlignment="Top" Width="82"/>
        <Label Name="lblDeployStatus" Content="" HorizontalAlignment="Left" Height="29" Margin="517,378,0,0" VerticalAlignment="Top" Width="312"/>
        <Image Name="imgLoading" Visibility="Hidden" HorizontalAlignment="Left" Height="100" Margin="454,341,0,0" VerticalAlignment="Top" Width="100" gif:ImageBehavior.AnimatedSource="\\files\kits$\Styles\Loading1.gif" Panel.ZIndex="-1"/>
        <Image Name="imgLoading3" Visibility="Hidden" HorizontalAlignment="Left" Height="200" Margin="475,70,0,0" VerticalAlignment="Top" Width="200" gif:ImageBehavior.AnimatedSource="\\files\kits$\Styles\Loading3.gif"/>

        <TextBox Name="txtRemark" HorizontalAlignment="Left" Margin="966,378,0,0" Text="" TextWrapping="Wrap" VerticalAlignment="Top" Width="174" Height="28"/>
        <Label Name="lblRemark" Content="Remark / Job number" HorizontalAlignment="Left" Height="27" Margin="837,378,0,0" VerticalAlignment="Top" Width="129"/>
        
        </Grid>
           </TabItem>
            <TabItem Header="      Log      ">
                <Grid Background="White">
                    <DataGrid Name="datLog" AutoGenerateColumns="False" HorizontalAlignment="Left" Height="550" Margin="10,0,0,0" VerticalAlignment="Center" Width="1130" CanUserSortColumns="False">
                        <DataGrid.Columns>

                             <DataGridTemplateColumn Header="DeployId" Width="60">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding DeployId, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="DeployBy" Width="80">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding DeployBy, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="DeployFrom" Width="120">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding DeployFrom, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="DeployTo" Width="120">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding DeployTo, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="DeploySoftware" Width="250">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding DeploySoftware, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="DeployTime" Width="120">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding DeployTime, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="EndTime" Width="120">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding EndTime, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="DeployResult" Width="100">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding DeployResult, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>

                             <DataGridTemplateColumn Header="Remark" Width="150">
                                <DataGridTemplateColumn.CellTemplate>                          
                                    <DataTemplate> 
                                        <TextBox Text="{Binding Remark, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" IsReadOnly="True" />
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                             </DataGridTemplateColumn>
                            
                         </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>
        </TabControl>


    </Grid>
</Window>


"@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader"; exit}

# Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}


# Initial data
$cmbCompName.Items.Add("Loading ...")
$cmbAvailablePackage.Items.Add("Loading ...")
$btnDeploy.IsEnabled = $False
$txtRemark.IsEnabled = $False
LoadJson -configfile $jsonfile
$global:objListComp = Get-ComputerList -sess $sess -Exe_Location $Exe_inventory
$global:objPDQPackage = Get-PDQPackage -sess $sess2 -Exe_Location $Exe_deploy

#Trigger timer event for backend
#Timer -ComputerList $ComputerList

#Create a timer
$timer = new-object System.Windows.Threading.DispatcherTimer 
$timer.Interval = New-TimeSpan -Seconds 2         
# And will invoke the $updateBlock 
         
$timer.Add_Tick({ DTimer })            
# Now start the timer running  
$timer.IsEnabled = $true          
$timer.Start()       


#Get-PDQPackage -sess $sess -Exe_Location $Exe_deploy
#Write-Host $ComputerList 

    <#
    $resultJob = Receive-Job -id $ComputerList.Id
    Write-Host  $ComputerList.State
    Write-Host  $ComputerList.Id
    Write-Host  $resultJob 

    # Wait until job is completed
    do{
        $jobName=$ComputerList.Name
        $jobState = (Wait-Job -Name $jobName).State
        write-host "Checking status of $jobName..."
        #sleep -seconds 1
        for ($i = 0; $i -lt 5; $i++)
        {
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.Application]::DoEvents()
        }
        if ($jobState -eq "Completed"){write-host "$jobName completed."}
    } until ($jobState -eq "Completed")    

    $result = receive-job $ComputerList.Id

    $Form.Resources.Add("ComputerList", $result)  
    #$ComputerList 
    #>



# Action
<#
$btnTimer.Add_Click({

    #$resultJob = Receive-Job -id $ComputerList.Id
    #Write-Host  $ComputerList.State
    #Write-Host  $ComputerList.Id
    #Write-Host  $resultJob
    
    # loop the timer every 2 seconds 
    for ($i = 0; $i -lt 10; $i++)
    {
        Start-Sleep -Milliseconds 200
        [System.Windows.Forms.Application]::DoEvents()
    }


    # Wait until job is completed
    if ($global:ListComp -ne "Completed"){
        do{
            $jobName = $ComputerList.Name
            $jobState = (Wait-Job -Name $jobName).State
            #write-host "Checking status of $jobName..."
            #sleep -seconds 1
            for ($i = 0; $i -lt 5; $i++)
            {
                Start-Sleep -Milliseconds 200
                [System.Windows.Forms.Application]::DoEvents()
            }
            if ($jobState -eq "Completed"){
                #write-host "$jobName completed."
                $global:ListComp = "Completed"
            }
        } until ($jobState -eq "Completed")    

        $resultJob = receive-job $ComputerList.Id

        $Form.Resources.Add("ComputerList", $resultJob)  
        #$ComputerList 
    }


})
#>

$btnSelect.Add_Click({

        #Write-Host $cmbCompName.Items.Count
        $global:Deploying = ""
        $txtRemark.Text = ""
        $comp = ""
        if($cmbCompName.Items.Count -ne 1){
            $comp = $cmbCompName.SelectedItem
        }
        #Write-Host $comp
        if($comp -eq "" -or $comp -eq $null -or $cmbCompName.Items.Count -eq 1){
             
            $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
            $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
            $MessageBody = "Please select a computer."
            $MessageTitle = "Warning"

            [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)    
            
        }else{

            $global:objListingApps = ListCompApps -sess $sess -Exe_Location $Exe_inventory -db $Inventory_db
            #Get-PDQPackage -sess $sess -Exe_Location $Exe_deploy

            $global:ListingApps = "Listing"

            #form control
            $imgLoading3.Visibility = "Visible"
            $cmbCompName.IsEnabled = $False
            $btnSelect.IsEnabled = $False
            $lblScanDate.Content = ""
            $lblCompStatus.Content = ""
            $global:Offline  = ""

        }
        #$imgLoading3.Visibility = "Hidden"
        <#
        $rootElement = [Windows.Automation.AutomationElement]::RootElement
        $condAUTProc = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ProcessIdProperty, $PID)
        $autElement = $rootElement.FindFirst([Windows.Automation.TreeScope]::Children, $condAUTProc)

        $condBtn = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ClassNameProperty, "Button")
        $condName = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty, "Debug")
        $condTarget = New-Object Windows.Automation.AndCondition($condBtn, $condName)
        $btn1Element = $autElement.FindFirst([Windows.Automation.TreeScope]::Descendants, $condTarget)
 

        $btn1Element.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
        #>

})

$btnDeploy.Add_Click({
    
        $global:Deploying = ""
        $package = ""
        if($cmbAvailablePackage.Items.Count -ne 1){
            $package = $cmbAvailablePackage.SelectedItem
        }
        #Write-Host $comp
        #$Package = $cmbAvailablePackage.SelectedItem.ToString()
        if($Package -eq "" -or $Package -eq $null -or $cmbAvailablePackage.Items.Count -eq 1){   
            
            $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
            $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
            $MessageBody = "Please select a package before deployment."
            $MessageTitle = "Warning"

            [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)    
            
        }else{
            $ComputerTarget = $cmbCompName.SelectedItem.ToString()
            $DeployPackage = "R-" + $cmbAvailablePackage.SelectedItem.ToString()
            # deploy software
            $global:objDeploySoftware = DeploySoftware -sess $sess -Exe_Location $Exe_deploy -target $ComputerTarget -package $DeployPackage -deploy_db $Deploy_db

            # update variable and status datagrid for timer
            $global:Exe_deploy2 = $Exe_deploy
            $global:ComputerTarget = $ComputerTarget
            $global:Deploy_db2 = $Deploy_db

            $global:Deploying = "Deploying"

            DisableButton
            #$imgLoading.Visibility = "Visible"
            $lblDeployStatus.Content= ""
        
        }


        #DeployStatus -sess $sess -Exe_Location $Exe_deploy -target $ComputerTarget -deploy_db $Deploy_db

        # set the refresh timer
        #Start-Sleep -s 2
        
        <#
        # loop the refresh button event and refresh status datagrid
        $rootElement = [Windows.Automation.AutomationElement]::RootElement
        $condAUTProc = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ProcessIdProperty, $PID)
        $autElement = $rootElement.FindFirst([Windows.Automation.TreeScope]::Children, $condAUTProc)

        $condBtn = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ClassNameProperty, "Button")
        $condName = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty, "Refresh")
        $condTarget = New-Object Windows.Automation.AndCondition($condBtn, $condName)
        $btn1Element = $autElement.FindFirst([Windows.Automation.TreeScope]::Descendants, $condTarget)
 
        $btn1Element.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
        #>
 })

<#
$btnRefresh.Add_Click({

        $ComputerTarget = $cmbCompName.SelectedItem.ToString()
        $Status_ind = DeployStatus -sess $sess -Exe_Location $Exe_deploy -target $ComputerTarget -deploy_db $Deploy_db

        #Write-Host "click " $Status_ind 

        if ($Status_ind -ne 1){

            # loop the refresh button event and refresh status datagrid
            $rootElement = [Windows.Automation.AutomationElement]::RootElement
            $condAUTProc = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ProcessIdProperty, $PID)
            $autElement = $rootElement.FindFirst([Windows.Automation.TreeScope]::Children, $condAUTProc)

            $condBtn = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ClassNameProperty, "Button")
            $condName = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty, "Refresh")
            $condTarget = New-Object Windows.Automation.AndCondition($condBtn, $condName)
            $btn1Element = $autElement.FindFirst([Windows.Automation.TreeScope]::Descendants, $condTarget)
 
            $btn1Element.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
        }else{
            #show finish msg
            #$cmbCompName.SelectedItem.ToString()
            #$cmbAvailablePackage.SelectedItem.ToString()

            $msg = $cmbAvailablePackage.SelectedItem.ToString() + " has been deployed to " + $cmbCompName.SelectedItem.ToString() + "`nPDQ inventory is updating " + $cmbCompName.SelectedItem.ToString() + "'s application list.`nPlease go back have a check later."

            $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
            $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Information
            $MessageBody = $msg
            $MessageTitle = "Done"

            [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        }
 
})
#>
<#
$btnDebug.Add_Click({

        #$ComputerTarget = "L02200-1ZC88H2"
        #$ComputerTarget = $cmbCompName.SelectedItem.ToString()
        #$Status_ind = DeployStatus -sess $sess -Exe_Location $Exe_deploy -target $ComputerTarget -deploy_db $Deploy_db

        Write-Host "click"
        #$imgLoading3.Visibility = "Visible"
        
         #write json log file
        $target = "L02200-1ZC88H2"
        $package = "123abc" 
        SaveJson -configfile $jsonfile -DeployTo $target -DeploySoftware $package -DeployId "123"

        #DisableButton

        #sleep -s 10
        #for ($i = 0; $i -lt 50; $i++)
        #{
        #    Start-Sleep -Milliseconds 200
        #    [System.Windows.Forms.Application]::DoEvents()
        #}


        #DeploySoftware -sess $sess -Exe_Location $Exe_deploy -target $ComputerTarget -package $DeployPackage
        #$tempObj = [pscustomobject]@{DeploymentID='a';DeployTarget='b';DeployStatus='c';DeploySteps='d';DeployError='e';ReturnCode='g';DeployStarted='f'}
        #$datDeployStatus.ItemsSource = $tempObj     
 
})
#>

<#
# trigger the timer button
$rootElement = [Windows.Automation.AutomationElement]::RootElement
$condAUTProc = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ProcessIdProperty, $PID)
$autElement = $rootElement.FindFirst([Windows.Automation.TreeScope]::Children, $condAUTProc)

$condBtn = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ClassNameProperty, "Button")
$condName = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty, "Timer")
$condTarget = New-Object Windows.Automation.AndCondition($condBtn, $condName)
$btnTimer = $autElement.FindFirst([Windows.Automation.TreeScope]::Descendants, $condTarget)
 
$btnTimer.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
#>



#Show Form
$Form.ShowDialog() | out-null
