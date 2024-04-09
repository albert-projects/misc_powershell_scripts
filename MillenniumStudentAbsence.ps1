#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12


$ie = New-Object -ComObject 'internetExplorer.Application'
$ie.Visible= $false # Make it visible
$username="msc"
$password="msc8325"
$site="moreesc"

$ie.Navigate("https://www.millenniumschools.net.au/admin/")
While ($ie.Busy -eq $true) {Start-Sleep -Seconds 3;}

$usernamefield = $ie.Document.getElementsByTagName("input") | ? { $_.name -eq "uname" }
$usernamefield.value = "$username"
$passwordfield = $ie.Document.getElementsByTagName("input") | ? { $_.name -eq "pwd" }
$passwordfield.value = "$password"
$sitefield = $ie.Document.getElementsByTagName("input") | ? { $_.name -eq "site" }
$sitefield.value = "$site"

#$Link = $ie.document.getElementByID('SubmitLogin')
#$Link.click()

$Link = $ie.Document.getElementsByTagName("input") | ? { $_.value -eq " LOG IN " }
if ($Link) { $Link.click() }


$url = "https://www.millenniumschools.net.au/admin/home/home.asp"
$ie.Navigate($url) 
While ($ie.Busy -eq $true) {Start-Sleep -Seconds 3;}
#$doc = $ie.document
#$web = New-Object Net.WebClient
#$web.DownloadString($url)

$ie2 = New-Object -ComObject 'internetExplorer.Application'
$ie2.Visible= $false
$ie2.Navigate($url) 
While ($ie2.Busy -eq $true) {Start-Sleep -Seconds 3;}
$doc = $ie2.document
$web = New-Object Net.WebClient
$web.DownloadString($url)

#$r = Invoke-WebRequest $url
#$r
#$r.Forms.fields | get-member
#$InnerText = $r.AllElements | 
#    Where-Object {$_.tagName -ne "TD" -and $_.innerText -ne $null} | 
#    Select -ExpandProperty innerText
#write-host $InnerText
#$r.AllElements|Where-Object {$_.InnerHtml -like "*=*"} 

#$doc = $ie.Document
#$doc.getElementByID("ext-element-7") | % {
#    if ($_.id -ne $null){
#        write-host $_.id
#    }
#}

$ie.Quit()