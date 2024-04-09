
#-----------------------------#
#   Set your variables here!  #
#-----------------------------#

## First, set the program location that exists under the user's profile. The rest of the script builds the beginning of the path.
$pathtoexe = '\AppData\Local\Temp\psiphon-tunnel-core.exe'
## Set the name you want the rule to be called in Windows Defender Advanced Firewall.
$firewallRuleName = 'Block_Psiphon'
## The script searches the scheduled task logs. Set the Scheduled Task name you intend to use here.
$scheduledtaskname = 'UpdateFirewallRule'
## Set the domain you want this to work in. To see what this value should be, run 'whoami' from a logged in user and look for the name before the \.
$domainname = "DETNSW"
## Set where you want your log file to save
$logfilepath = 'C:\DECApps\Logs\FWRules.log'

#-----------------------------#
# Here's the actual code part #
#-----------------------------#

function Get-TimeStamp
{
return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)         
}

Write-Output "$(Get-TimeStamp) Script triggered due to login." | out-file -filepath $logfilepath -append
# Sleeping for 2 seconds to allow log to be written. This value can be tweaked for slower\faster systems (primarly HDD vs SSD), but it should exist with a value of at least 2.
Start-Sleep 2
# Searching the Task Scheduler log in the last minute to see who triggered the script, returns the first hit only, then captures the DOMAIN\USERNAME value only.
<
$LastLoggedOnUserFull = Get-WinEvent -FilterHashtable @{logname=”Microsoft-Windows-TaskScheduler/Operational”;ID=119;starttime=((Get-Date).AddMinutes(-1))} | Where {$_.Message -match $scheduledtaskname} | select -first 1 @{N='User';E={$_.Properties[1].Value}} | select -expand User

if (!$LastLoggedOnUserFull)
{
Write-Output "$(Get-TimeStamp) Script ending due to no user found." | out-file -filepath $logfilepath -append
exit
}

Write-Output "$(Get-TimeStamp) $LastLoggedOnUserFull found in event log" | out-file -filepath $logfilepath -append

#$LastLoggedOnUserFull = "DETNSW\hkwan"

## Trim the domain out of the username
$LastLoggedOnUser = $LastLoggedOnUserFull.Trim("$domainname\")

# Couldn't find a variable for the general users directory (since it's not always C:\Users), so instead I use the Public environment and trim the folder from the result.
$PrimaryUserFolders = $env:public.Trim("\Public")

# Combine everything to make a file path for the user to the requested program.
$ProgramLoc = $PrimaryUserFolders + "\$LastLoggedOnUser" + $pathtoexe
#write-host TCP*$ProgramLoc

# Now taking the file path created above to search existing firewall rules. 


$RuleAddedByPsiphonBlocked = Get-NetFirewallRule -Name "*$firewallRuleName*" -ErrorAction SilentlyContinue | select name, action
$RuleAlreadyAdded = Get-NetFirewallRule -Name "$firewallRuleName Any Deny for $LastLoggedOnUser via script" -ErrorAction SilentlyContinue | select name, action

# Delete existing block rule if it exists, build the proper rules if they don't exist.

if($RuleAddedByPsiphonBlocked){
    if($RuleAlreadyAdded)
    {
        Write-Output "$(Get-TimeStamp) Existing firewall rule for Psiphon for $lastloggedonuser." | out-file -filepath $logfilepath -append
    }else{
        Remove-NetFirewallRule -name $RuleAddedByPsiphonBlocked.name
        Write-Output "$(Get-TimeStamp) Block rule for another user has been removed." | out-file -filepath $logfilepath -append

    }
}


    if(!$RuleAlreadyAdded)
    {
        New-NetfirewallRule -DisplayName $firewallRuleName -name "$firewallRuleName Any Deny for $LastLoggedOnUser via script" -Direction Outbound -Protocol Any -Profile Any -Program $ProgramLoc -Action Block
        Write-Output "$(Get-TimeStamp) New Blocked Psiphon firewall rule added for $LastLoggedOnUser" | out-file -filepath $logfilepath -append
    }
    elseif($RuleAlreadyAdded.action = 'Block')
    {
        Write-Output "$(Get-TimeStamp) Nothing to do. Existing Block firewall rule for $lastloggedonuser already set to block." | out-file -filepath $logfilepath -append
    }


<#
$TCPRuleAddedByTeamsBlocked = Get-NetFirewallRule -Name TCP*$ProgramLoc -ErrorAction SilentlyContinue | select name, action
$UDPRuleAddedByTeamsBlocked = Get-NetFirewallRule -Name UDP*$ProgramLoc -ErrorAction SilentlyContinue | select name, action

$TCPRuleAlreadyAdded = Get-NetFirewallRule -Name "$firewallRuleName TCP Allow for $LastLoggedOnUser via script" -ErrorAction SilentlyContinue | select name, action
$UDPRuleAlreadyAdded = Get-NetFirewallRule -Name "$firewallRuleName UDP Allow for $LastLoggedOnUser via script" -ErrorAction SilentlyContinue | select name, action

# Delete existing block rule if it exists, build the proper rules if they don't exist.
 
if(!$TCPRuleAddedByTeamsBlocked)
{
Write-Output "$(Get-TimeStamp) Nothing to do. Existing block TCP firewall rule for $lastloggedonuser does not exist." | out-file -filepath $logfilepath -append
}
elseif($TCPRuleAddedByTeamsBlocked.action = "Block")
{
Remove-NetFirewallRule -name $TCPRuleAddedByTeamsBlocked.name
Write-Output "$(Get-TimeStamp) TCP Block rule for $lastloggedonuser removed." | out-file -filepath $logfilepath -append
}

if(!$UDPRuleAddedByTeamsBlocked)
{
Write-Output "$(Get-TimeStamp) Nothing to do. Existing block UDP firewall rule for $lastloggedonuser does not exist." | out-file -filepath $logfilepath -append
}
elseif($UDPRuleAddedByTeamsBlocked.action = "Block")
{
Remove-NetFirewallRule -name $UDPRuleAddedByTeamsBlocked.name
Write-Output "$(Get-TimeStamp) UDP Block rule for $lastloggedonuser removed." | out-file -filepath $logfilepath -append
}

if(!$TCPRuleAlreadyAdded)
{
New-NetfirewallRule -DisplayName $firewallRuleName -name "$firewallRuleName TCP Allow for $LastLoggedOnUser via script" -Direction Inbound -Protocol TCP -Profile Any -Program $ProgramLoc -Action Allow -EdgeTraversalPolicy DeferToUser
Write-Output "$(Get-TimeStamp) New TCP firewall rule added for $LastLoggedOnUser" | out-file -filepath $logfilepath -append
}
elseif($TCPRuleAlreadyAdded.action = 'Allow')
{
Write-Output "$(Get-TimeStamp) Nothing to do. Existing TCP firewall rule for $lastloggedonuser already set to allow." | out-file -filepath $logfilepath -append
}

if(!$UDPRuleAlreadyAdded)
{
New-NetfirewallRule -DisplayName $firewallRuleName -name "$firewallRuleName UDP Allow for $LastLoggedOnUser via script" -Direction Inbound -Protocol UDP -Profile Any -Program $ProgramLoc -Action Allow -EdgeTraversalPolicy DeferToUser
Write-Output "$(Get-TimeStamp) New UDP firewall rule added for $LastLoggedOnUser" | out-file -filepath $logfilepath -append
}
elseif($UDPRuleAlreadyAdded.action = 'Allow')
{
Write-Output "$(Get-TimeStamp) Nothing to do. Existing UDP firewall rule for $lastloggedonuser already set to allow." | out-file -filepath $logfilepath -append
}

#>