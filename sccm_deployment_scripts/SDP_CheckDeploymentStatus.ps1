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
$task_result2 = Get-Content $json_file | Out-String | ConvertFrom-Json

# PDQ execution path
$Exe_inventory = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\"
$Exe_deploy = "C:\Program Files (x86)\Admin Arsenal\PDQ Deploy\"

# PDQ SQL Lite database file path
$Inventory_db = "C:\ProgramData\Admin Arsenal\PDQ Inventory\Database.db"
$Deploy_db = "C:\ProgramData\Admin Arsenal\PDQ Deploy\Database.db"



$txt = "\\vwspmsdt01\MDT_Logs\SD_testing.txt"
$time = Get-Date -format "dd-MMM-yyyy HH:mm:ss"

#$time | Out-File -FilePath $txt -Append

<#
# retrieve the data from database
$Query = "select Deployments.DeploymentId
            from deployments
            left join DeploymentComputers 
            on Deployments.DeploymentId = DeploymentComputers.DeploymentId
            where Deployments.PackageName = 'SDP_CheckDeploymentResult'
            and DeploymentComputers.ShortName = '" + $target + "'
            and DeploymentComputers.Status = 'Running' limit 1;"

$DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_deploy, $deploy_db, $Query -ScriptBlock {

            param($Exe_deploy, $Database, $Query)

            Set-Location -Path $Exe_deploy;
            $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
            #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
            #Write-Host $result
            Return $result
        }
#>

#write-host $DeployProgress.DeploymentId.ToString()

# find the task detail in json result
$ran = "0"
$exceed_retry = "0"
foreach( $request_task in $task_result.request_task ) { 

    #Write-Host "in node"
    #$request_task.deployment_id

    if ( $request_task.deploy_software -eq "SDP_CheckDeploymentResult" -and $request_task.status -eq "Pending" ){
        
        #Write-Host $request_task.check_deployment_id
        #Write-Host $request_task.deployment_id
        $checking_task = $request_task.check_deployment_id
        $checking_task = $checking_task.ToString()
        #$json_target = $request_task.target_pc
        #$json_deploy_software = $request_task.check_deploy_software
        #$json_request_id = $request_task.request_id
        #$json_task_id = $request_task.task_id

        foreach( $request_task2 in $task_result2.request_task ) { 
                
                if ( $request_task2.deployment_id -eq $checking_task -and $request_task2.status -eq "Pending" ){
               
                    #the task in retry queue
                    $request_id = $request_task2.request_id
                    $task_id = $request_task2.task_id
                    $num_retry = $request_task2.retry
                    $num_retry = [int]$num_retry

                    # update the note
                    $url = "https://servicedesk:9999/api/v3/requests/" + $request_id + "/notes"
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

                        #do find the biggest id
                        $note_id = $response.notes.id

                        # get current note description
                        $url = "https://servicedesk:9999/api/v3/requests/" + $request_id + "/notes/" + $note_id
                        $technician_key = @{ 'authtoken' = ''}
                        $technician_key.authtoken = $API_Key

                        $response = Invoke-RestMethod -Uri $url -Method get -Headers $technician_Key
                        $response
                        $note_description = $response.note.description
            
                        $index = $note_description.IndexOf('<div>------')
                        $note_description = $note_description.SubString(0,$index)
                        #$note_description

                        #update number of retry
                        $num_retry++
                        $num_retry2 = $num_retry.ToString()

                        # update note
                        $url = "https://servicedesk:9999/api/v3/requests/" + $request_id + "/notes/" + $note_id
                        $technician_key = @{ 'authtoken' = ''}
                        $technician_key.authtoken = $API_Key

                        #$package | Out-File -FilePath $txt -Append
                        #$package_name = $package.substring( 4, $package.Length -4)

                        $input_data = '
                        {
                            "note": {
                                "description": "' + $note_description + '<div>------<br/></div><div>' + $time + ': Status : The task is in the retry queue. Retried ' + $num_retry2 + ' time(s).<br/></div>",
                                "show_to_requester": true,
                                "mark_first_response": false,
                                "add_to_linked_requests": true
                            }
                        }
                        '
                        $data = @{ 'input_data' = $input_data}
                        $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
                        $response

                        # update the status to "Onhold"
                        $url = "https://servicedesk:9999/api/v3/requests/" + $request_id
                        $technician_key = @{ 'authtoken' = ''}
                        $technician_key.authtoken = $API_Key

                        $input_data = @'
{
    "request": {

        "status": {
            "color": "#ff0000",
            "name": "Onhold",
            "id": "3"
        }
    }
}
'@
                        $data = @{ 'input_data' = $input_data}
                        $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
                        $response


                        #update retry in json
                        $request_task2.retry = $num_retry2
                        
                        # if retry times > 672(7 days)
                        if($num_retry -ge 672){                  
                            $request_task2.status = "Failed"    
                            $exceed_retry = $request_task2.deployment_id
                                            
                        }
                        # save back to json file
                        $task_result2 | ConvertTo-Json -Depth 5 | Out-File -FilePath $json_file -Force                                                     
                            
                    }
   
                }
                # if the task has been ran
                if ( $request_task2.deployment_id -eq $checking_task -and $request_task2.status -eq "Ran" ){

                    $json_target = $request_task2.target_pc
                    $json_package = $request_task2.deploy_software
                    $json_request_id = $request_task2.request_id
                    $json_task_id = $request_task2.task_id
                
                    # search the deployment result in PDQ database
                    $Query = "select DeploymentId, ShortName, Error, Status 
                              from DeploymentComputers
                              where DeploymentId = " + $checking_task + " and ShortName = '" + $json_target + "' limit 1;"


                    $DeployProgress = Invoke-Command -Session $sess -ArgumentList $Exe_deploy, $deploy_db, $Query -ScriptBlock {

                                param($Exe_deploy, $Database, $Query)

                                Set-Location -Path $Exe_deploy;
                                $result = Invoke-SqliteQuery -Query $Query -DataSource $Database
                                #$lastexitcode = PDQInventory.exe GetAllComputers | Where-Object {$_.psobject.baseobject.tostring() -like 'A0*' -or $_.psobject.baseobject.tostring() -like 'D0*' -or $_.psobject.baseobject.tostring() -like 'L0*' -or $_.psobject.baseobject.tostring() -like 'T0*' };
                                #Write-Host $result
                                Return $result
                            }

                    $deplopment_status = $DeployProgress.Status.ToString()

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

                        $index = $note_description.IndexOf('<div>------')
                        $note_description = $note_description.SubString(0,$index)

                        #------------------------ remarkline --------
                        # update note
                        #$url = "https://servicedesk:9999/api/v3/requests/" + $request_id + "/notes/" + $note_id
                        $technician_key = @{ 'authtoken' = ''}
                        $technician_key.authtoken = $API_Key

                        #$package | Out-File -FilePath $txt -Append
                        $package_name = $json_package.substring( 4, $json_package.Length -4)

                        $input_data = '
                        {
                            "note": {
                                "description": "<div>' + $time + ': ' + $package_name + ' has been deployed to ' + $json_target + '.</br></div>' + $note_description + '<div>------<br/></div><div>' + $time + ': Status : ' + $package_name + ' has been deployed to ' + $json_target + '.<br/></div>",
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

        #update request status
        $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key

        $input_data = @'
{
    "request": {

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


        # update the json file to successful
        $ran = $request_task2.deployment_id
        $request_task2.status = "Successful"
        # save back to json file
        $task_result2 | ConvertTo-Json -Depth 5 | Out-File -FilePath $json_file -Force


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
            
        $index = $note_description.IndexOf('<div>------')
        $note_description = $note_description.SubString(0,$index)
        #$note_description

         
        # update note
        $url = "https://servicedesk:9999/api/v3/requests/" + $json_request_id + "/notes/" + $note_id
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key
        $package_name = $json_package.substring( 4, $json_package.Length -4)
        #$package_name


        #write-host $DeployProgress.DeploymentId.ToString()
        #write-host $DeployProgress.ShortName.ToString()
        #write-host $DeployProgress.Error.ToString()
        #write-host $DeployProgress.Status.ToString()

        $error_msg = [xml]$DeployProgress.Error.ToString()
        $error_msg = $error_msg.Error.Message

        $input_data = '
            {
                "note": {
                    "description": "<div>' + $time + ': ' + $package_name + ' failed to deployed to ' + $json_target + '. Error Message: ' + $error_msg + '.</br></div>' + $note_description + '<div>------<br/></div><div>' + $time + ': Status : Failed to deploy ' + $package_name + ', please go to PDQ Server for detail information.<br/></div>",
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

        # update the json file to failed
        $ran = $request_task2.deployment_id
        $request_task2.status = "Failed"
        # save back to json file
        $task_result2 | ConvertTo-Json -Depth 5 | Out-File -FilePath $json_file -Force

}



                }

        }

    }
}

# update SDP_CheckDeploymentResult json
$task_result3 = Get-Content $json_file | Out-String | ConvertFrom-Json

foreach( $request_task3 in $task_result3.request_task ) { 

    #Write-Host "in node"
    #$request_task.deployment_id

    if ( $request_task3.deploy_software -eq "SDP_CheckDeploymentResult" -and $request_task3.status -eq "Pending" -and $request_task3.check_deployment_id -eq $ran ){
        $request_task3.status = "Done"
    }
    if ( $request_task3.deploy_software -eq "SDP_CheckDeploymentResult" -and $request_task3.status -eq "Pending" -and $request_task3.check_deployment_id -eq $exceed_retry ){
        $request_task3.status = "Done"
        $request_task3.retry = "RetryQueueExceed"

        $request_id = $request_task3.request_id
        $task_id = $request_task3.task_id

        #set the request to failure
        # update the note
        $url = "https://servicedesk:9999/api/v3/requests/" + $request_id + "/notes"
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
        $url = "https://servicedesk:9999/api/v3/requests/" + $request_id + "/notes/" + $note_id
        $technician_key = @{ 'authtoken' = ''}
        $technician_key.authtoken = $API_Key
        
        $response = Invoke-RestMethod -Uri $url -Method get -Headers $technician_Key
        $response
        $note_description = $response.note.description
            
        $input_data = '
            {
                "note": {
                    "description": "' + $note_description + '<div>' + $time + ': Status : Retry limit exceeded, retry queue stopped.<br/></div>",
                    "show_to_requester": true,
                    "mark_first_response": false,
                    "add_to_linked_requests": true
                }
            }
            '
        $data = @{ 'input_data' = $input_data}
        $response = Invoke-RestMethod -Uri $url -Method put -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
        $response

        # update task status
        #$json_request_id
        #$json_task_id 
        $url = "https://servicedesk:9999/api/v3/requests/" + $request_id + "/tasks/" + $task_id
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


    }

}
# save back to json file
$task_result3 | ConvertTo-Json -Depth 5 | Out-File -FilePath $json_file -Force


#write-host $DeployProgress.DeploymentId.ToString()
#write-host $DeployProgress.ShortName.ToString()
#write-host $DeployProgress.Error.ToString()
#write-host $DeployProgress.Status.ToString()



#$json_request_id
#$json_task_id 
#$json_target 
#$json_deploy_software 



Remove-PSSession $sess