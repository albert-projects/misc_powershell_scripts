#$OUPath = "OU=Accounts,OU=Moree Sec College Albert St Campus,OU=New England,OU=Schools,DC=DETNSW,DC=WIN"
$OUPath = "OU=Moree Sec College Carol Ave Campus,OU=New England,OU=Schools,DC=DETNSW,DC=WIN"
Get-ADUser -Filter * -SearchBase $OUPath | Select-Object name,SamAccountName,UserPrincipalName | Export-csv C:\Users\hkwan\Documents\export2.csv