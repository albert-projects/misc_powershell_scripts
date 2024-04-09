

$File_Location = "\\files\PUBLIC\Logs\GPResult"
$User_csv = "$File_Location\UserOU_ToBeDone.csv"

# import the User OU csv file
$User_list = Import-Csv $User_csv

Foreach ($User in $User_list) {

     write-host $User.UserID

     #remove testing acccount security group





}








write-output "Connecting to Computername"
$Server   = "V00000-ALBERT1"
$User     = "albert_testing"
$Password = "Password123!"

cmdkey /delete:"$Server" 
cmdkey /generic:"$Server" /user:"$user" /pass:"$password"

mstsc /v:"$Server" /admin /w:200 /h:150 