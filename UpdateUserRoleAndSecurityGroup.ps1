
Import-Module ActiveDirectory

function Clear_SecurityGroup {

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $User
    )

    #remove user's security group
    $sourceUserMemberOf = Get-AdUser $user -Properties MemberOf -ErrorAction Stop
    
    Foreach ($group in $sourceUserMemberOf.MemberOf){
       Remove-adgroupmember -identity $group -members $User -Confirm:$false
    }
}

function Add_SecurityGroup {

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $User,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Group
    )

    #add security group to user
    $groupInfo = Get-AdGroup $Group 
    $groupName = $groupInfo.Name
    $groupInfo | Add-ADGroupMember -Members $User -ErrorAction Stop 
    Write-Host "Added user to group '$groupName'"

}

Clear_SecurityGroup -User albert_testing
Add_SecurityGroup -User albert_testing -Group Security-Role-ExecutiveAssistantPCDTemp-32
