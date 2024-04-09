
#json file 
$json_file = "\\vwspmsdt01\SDP\result\result.json"

$task_result = Get-Content $json_file | Out-String | ConvertFrom-Json

foreach( $request_task in $task_result.request_task ) { 

    #Write-Host "in node"
    #$request_task.deployment_id

    if ( $request_task.check_deployment_id -eq "10379"){
        
        Write-Host $request_task.check_deployment_id
        Write-Host $request_task.deployment_id

    }

}