
$technician_key = @{ 'authtoken' = '<Your token>'}
#Powershell version - 5.1
$url = "https://servicedesk:9999/api/v3/problems"
$input_data = @'
{
    "problem": {
        "title": "testing create problem from API"
    }
}
'@
$data = @{ 'input_data' = $input_data}
$response = Invoke-RestMethod -Uri $url -Method post -Body $data -Headers $technician_Key -ContentType "application/x-www-form-urlencoded"
$response
