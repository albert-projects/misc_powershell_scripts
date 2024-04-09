
param (
$json = "none"
)

$jsondata = Get-Content $json -Encoding UTF8 #Encode if necessary
$obj = ConvertFrom-Json $jsondata

$workorderid = $obj.request.WORKORDERID
$requester = $obj.request.REQUESTER
$createdtime = $obj.request.createdtime
$subject = $obj.request.SUBJECT
$category = $obj.request.category
$technician = $obj.request.technician
$status = $obj.request.status
$priority = $obj.request.priority
$requesttype = $obj.request.requesttype
$group = $obj.request.group
$description = $obj.request.description
$cc = $obj.request.interestedparty

$sdphost = "https:///servicedesk/"
$techkey = "41EA19D0-3C84-48D1-AEE0-85DD3A3ECE94"

$url = $sdphost + "sdpapi/request/" + $workorderid + "/notes"
$method = "POST"
$operation = "ADD_NOTE"

$url2 = $sdphost + "api/v3/request/" + $workorderid + "/share"
$method2 = "POST"
$operation2 = "SHARE_REQUEST"

###############################################
########### Script action from here ###########
###############################################

Import-Module ActiveDirectory

#Convert initials to SAMAccountName
$SAMaccount = Get-ADUser -Filter {Name -eq $requester} | Select-Object sAMAccountName -ExpandProperty sAMAccountName

#Convert CC email to user name
$bruger = Get-ADUser -Filter "emailaddress -eq '$cc'" | Select-Object name -ExpandProperty name

$ActionTaken = "Script: Request has been shared with the user specified in Cc."

# Configure input data for adding note to request
$inputStatus = @"
{
"operation": {
"details": {
"notes": {
"note": {
"ispublic": "false",
"notestext": "$ActionTaken"
}
}
}
}
}
"@

#Create note
$paramsStatus = @{INPUT_DATA=$inputStatus;OPERATION_NAME=$operation;TECHNICIAN_KEY=$techkey;format='json'}
$resultStatus = Invoke-WebRequest -Uri $url -Method POST -Body $paramsStatus

#Share input data version 1
$inputStat1 = @"
<share>
<technicians>
<name>$bruger</name>
</technicians>
</share>
"@

#Share input data version 2
$inputStat2 = @"
{
"share": {
"technicians": [
"name": "$bruger"
]
}
}
"@

$paramsStat = @{INPUT_DATA=$inputStat1;OPERATION_NAME=$operation2;TECHNICIAN_KEY=$techkey}
$resultStat = Invoke-WebRequest -Uri $url2 -Method POST -Body $paramsStat