#Value  Description   
#0 Show OK button. 
#1 Show OK and Cancel buttons. 
#2 Show Abort, Retry, and Ignore buttons. 
#3 Show Yes, No, and Cancel buttons. 
#4 Show Yes and No buttons. 
#5 Show Retry and Cancel buttons. 
#http://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx

#$a = new-object -comobject wscript.shell 
#$intAnswer = $a.popup("MDT and PDQ finished, please logon the machine for more details.",999999,"MDT Process",0) #first number is timeout, second is display.

#7 = no , 6 = yes, -1 = timeout

$ComputerName=$args[0]
$msg=$args[1]

if($msg -eq "1" ){
    $message = "C:\windows\system32\msg.exe *  /TIME:999999 The computer will do the Sophos Anti-Virus upgrade progress at 2 minutes later.`nThe computer will reboot twice by then, please save all your editing documents immediately.`nIf your have any questing, please contact IT Dept."
}

if($msg -eq "2" ){
    $message = "C:\windows\system32\msg.exe *  /TIME:999999 Sophos Anti-Virus upgrading.`nIf your have any questing, please contact IT Dept."
}

Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $message -ComputerName $ComputerName