# get parameter
$target=$args[0]
#$target = "L02200-1ZC88H2"

# the process will run as the owner of the API Key
$API_Key = "73049681-240C-4A3A-A0B0-5A98DA63A202" # Albert's API Key

# Set credential to MPSC\PDQ user for vwspmsdt01
$Cred = [System.Management.Automation.PSCredential]::new("mpsc\pdq",$("Secretus1519!" | ConvertTo-SecureString -AsPlainText -Force))
$pso = New-PSSessionOption –NoMachineProfile
$sess = New-PSSession -ComputerName vwspmsdt01 -SessionOption $pso -credential $Cred

#json file 
$json_file = "\\vwspmsdt01\SDP\result\result.json"
$task_result = Get-Content $json_file | Out-String | ConvertFrom-Json

# PDQ execution path
$Exe_inventory = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\"
$Exe_deploy = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

# PDQ SQL Lite database file path
$Inventory_db = "C:\ProgramData\Admin Arsenal\PDQ Inventory\Database.db"
$Deploy_db = "C:\ProgramData\Admin Arsenal\PDQ Deploy\Database.db"



$txt = "\\vwspmsdt01\MDT_Logs\debug.txt"
$time = Get-Date -format "dd-MMM-yyyy HH:mm:ss"

#$time | Out-File -FilePath $txt -Append


# retrieve the current deployment id from database
$Query = "select Deployments.DeploymentId, Deployments.PackageName
            from deployments
            left join DeploymentComputers 
            on Deployments.DeploymentId = DeploymentComputers.DeploymentId
            where DeploymentComputers.ShortName = '" + $target + "'
            and DeploymentComputers.Status = 'Running' limit 1;"


$DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_deploy, $deploy_db, $Query -ScriptBlock {

            param($Exe_deploy, $Database, $Query)

            Set-Location -Path $Exe_deploy;
            $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
            #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
            #Write-Host $result
            Return $result
        }

#write-host $DeployProgress.DeploymentId.ToString() | Out-File -FilePath $txt -Append
#$DeployProgress.DeploymentId.ToString() | Out-File -FilePath $txt -Append

# find the task detail in json result
$retry_queue = "yes"
$current_deployment_id = $DeployProgress.DeploymentId.ToString()
$current_package_name = $DeployProgress.PackageName.ToString()

foreach( $request_task in $task_result.request_task ) { 

    #Write-Host "in node"
    #$request_task.deployment_id

    if ( $request_task.deployment_id -eq $DeployProgress.DeploymentId.ToString() -and $request_task.status -eq "Pending"){

        # find existing deployment id
        $retry_queue = "no"

        # update json file to "Ran"
        $request_task.status = "Ran"
    }

}

if ($retry_queue -eq "no"){
    # save back to json file
    $task_result | ConvertTo-Json -Depth 5 | Out-File -FilePath $json_file -Force
}

if ($retry_queue -eq "yes"){

    #found retry queue, update deployment id in json file
    $Query = "select DeploymentComputers.DeploymentId, DeploymentComputers.Error, DeploymentComputers.ShortName, deployments.PackageName
                from DeploymentComputers, deployments
                where DeploymentComputers.DeploymentId = deployments.DeploymentId
                and deployments.PackageName = '" + $current_package_name + "'
                and DeploymentComputers.ShortName = '" + $target + "'
                and DeploymentComputers.Status = 'Failed'
                and (Cast(DeploymentComputers.Error as text) like '%Could not ping computer%' 
                or Cast(DeploymentComputers.Error as text) like '%Could not Wake on LAN%')
                order by DeploymentComputers.DeploymentId desc limit 1;"


    $DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_deploy, $deploy_db, $Query -ScriptBlock {

                param($Exe_deploy, $Database, $Query)

                Set-Location -Path $Exe_deploy;
                $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
                #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
                #Write-Host $result
                Return $result
            }
    
    $old_deployment_id = $DeployProgress.DeploymentId.ToString()
    $sdp_notes = 0
                
    # replace old deployment id with current id
    foreach( $request_task in $task_result.request_task ) { 

        #Write-Host "in node"
        #$request_task.deployment_id

        if ( $request_task.deployment_id -eq $old_deployment_id){

            # find existing deployment id
            $request_task.deployment_id = $current_deployment_id
            #$request_task.time = $time
            #$json_time = $time

            if ( $request_task.check_deployment_id -eq "null"){
                #$sdp_notes = 1
                $json_request_id = $request_task.request_id
                $json_task_id = $request_task.task_id
                $json_target = $request_task.target_pc
                $json_deploy_software = $request_task.deploy_software
                $json_time = $request_task.time

                $request_task.status = "Ran"

            }
            $request_task.time = $time
            
        }
        if ( $request_task.check_deployment_id -eq $old_deployment_id){

            # find existing deployment id
            $request_task.check_deployment_id = $current_deployment_id
        }
    }

    # save back to json file
    $task_result | ConvertTo-Json -Depth 5 | Out-File -FilePath $json_file -Force

    # update to SDP with api
    if ($sdp_notes -eq 1) {

        #do api update to SDP request_note 
        $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes"
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key

    $input_data = @'
    {
        "list_info": {
            "row_count": 1,
            "start_index": 1,
            "sort_field": "id",
            "sort_order": "desc",
            "get_total_count": true
        }
    }
'@

        $data = @{ 'input_data' = $input_data}
        $response = Invoke-RestMethod -Uri $url -Method get -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
        $response  
        
        if($response.list_info.total_count -gt "0"){
        
            $note_id = $response.notes.id
        
            # get current note description
            $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes/" + $note_id
            $technician_key = @{ 'authtoken' = ''}
            $technician_key.authtoken = $API_Key
        
            $response = Invoke-RestMethod -Uri $url -Method get -Headers $technician_Key
            $response
            $note_description = $response.note.description

         
            # update note
            $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes/" + $note_id
            $technician_key = @{ 'authtoken' = ''}
            $technician_key.authtoken = $API_Key
            $package_name = $json_deploy_software.substring( 4, $json_deploy_software.Length -4)

            $input_data = '
                {
                    "note": {
                        "description": "<div>' + $time + ':  Failed to deploy at ' + $json_time + ', re-scheduled the deployment into retry queue.</br></div>' + $note_description + '",
                        "show_to_requester": true,
                        "mark_first_response": false,
                        "add_to_linked_requests": true
                    }
                }
                '
            $data = @{ 'input_data' = $input_data}
            $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
            $response    
        }         
    
    }

}

<#
# search the deployment result in PDQ database
$Query = "select DeploymentId, ShortName, Error, Status 
          from DeploymentComputers
          where DeploymentId = " + $checking_task + " and ShortName = '" + $target + "' limit 1;"


$DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_deploy, $deploy_db, $Query -ScriptBlock {

            param($Exe_deploy, $Database, $Query)

            Set-Location -Path $Exe_deploy;
            $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
            #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
            #Write-Host $result
            Return $result
        }

#write-host $DeployProgress.DeploymentId.ToString()
#write-host $DeployProgress.ShortName.ToString()
#write-host $DeployProgress.Error.ToString()
#write-host $DeployProgress.Status.ToString()

$deplopment_status = $DeployProgress.Status.ToString()
#>

#$json_request_id
#$json_task_id 
#$json_target 
#$json_deploy_software 

<#
if( $deplopment_status -eq "Successful" ){

    #do api update to SDP request_note 
    $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes"
    $technician_key = @{ 'authtoken' = ''}
    $technician_key.authtoken = $API_Key

$input_data = @'
{
    "list_info": {
        "row_count": 1,
        "start_index": 1,
        "sort_field": "id",
        "sort_order": "desc",
        "get_total_count": true
    }
}
'@

    $data = @{ 'input_data' = $input_data}
    $response = Invoke-RestMethod -Uri $url -Method get -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
    $response

    if($response.list_info.total_count -gt "0"){
        
        $note_id = $response.notes.id
        
        # get current note description
        $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes/" + $note_id
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key
        
        $response = Invoke-RestMethod -Uri $url -Method get -Headers $technician_Key
        $response
        $note_description = $response.note.description

         
        # update note
        $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes/" + $note_id
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key
        $package_name = $json_deploy_software.substring( 4, $json_deploy_software.Length -4)

        $input_data = '
            {
                "note": {
                    "description": "<div>' + $time + ': ' + $package_name + ' has been deployed to ' + $json_target + '.</br></div>' + $note_description + '",
                    "show_to_requester": true,
                    "mark_first_response": false,
                    "add_to_linked_requests": true
                }
            }
            '
        $data = @{ 'input_data' = $input_data}
        $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
        $response
    
    }

    # update task status
    #$json_request_id
    #$json_task_id 
    $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/tasks/" + $json_task_id
    $technician_key = @{ 'authtoken' = ''}
    $technician_key.authtoken = $API_Key
   
    $input_data = @'
        {
            "task": {
                "percentage_completion": 100,
                "status": {
                "color": "#00ff66",
                "name": "Resolved",
                "id": "4"
                }
            }
        }
'@
        $data = @{ 'input_data' = $input_data}
        $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
        $response


}elseif($deplopment_status -eq "Failed" ){

    #do api update to SDP request_note 
    $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes"
    $technician_key = @{ 'authtoken' = ''}
    $technician_key.authtoken = $API_Key

$input_data = @'
{
    "list_info": {
        "row_count": 1,
        "start_index": 1,
        "sort_field": "id",
        "sort_order": "desc",
        "get_total_count": true
    }
}
'@

    $data = @{ 'input_data' = $input_data}
    $response = Invoke-RestMethod -Uri $url -Method get -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
    $response

    if($response.list_info.total_count -gt "0"){
        
        $note_id = $response.notes.id
        
        # get current note description
        $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes/" + $note_id
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key
        
        $response = Invoke-RestMethod -Uri $url -Method get -Headers $technician_Key
        $response
        $note_description = $response.note.description

         
        # update note
        $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes/" + $note_id
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key
        $package_name = $json_deploy_software.substring( 4, $json_deploy_software.Length -4)
        #$package_name


        #write-host $DeployProgress.DeploymentId.ToString()
        #write-host $DeployProgress.ShortName.ToString()
        #write-host $DeployProgress.Error.ToString()
        #write-host $DeployProgress.Status.ToString()

        $error = [xml]$DeployProgress.Error.ToString()
        $error_msg = $error.Error.Message

        $input_data = '
            {
                "note": {
                    "description": "<div>' + $time + ': ' + $package_name + ' failed to deployed to ' + $json_target + '. Error Message: ' + $error_msg + '.</br></div>' + $note_description + '",
                    "show_to_requester": true,
                    "mark_first_response": false,
                    "add_to_linked_requests": true
                }
            }
            '
        $data = @{ 'input_data' = $input_data}
        $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
        $response
    
    }

    # update task status
    #$json_request_id
    #$json_task_id 
    $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/tasks/" + $json_task_id
    $technician_key = @{ 'authtoken' = ''}
    $technician_key.authtoken = $API_Key
   
    $input_data = @'
        {
            "task": {
                "percentage_completion": 100,
                "status": {
                "color": "#006600",
                "name": "Closed",
                "id": "1"
            }
            }
        }
'@
        $data = @{ 'input_data' = $input_data}
        $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
        $response

}
#>

Remove-PSSession $sess