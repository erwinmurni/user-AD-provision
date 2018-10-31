#To Add user into Azure Group and assign O365 license
#Create C:\Temp\Group.txt file with group name that you want to assign user into
#Change the O365 license with your company O365 subscription, used Get-MsolAccountSku

Write-Host "Please add group name in C:\Temp\Group.txt file before proceed" -ForegroundColor Yellow
$user=read-host 'Enter user Display Name (First and Last Name) to add to group'
$user_search = Get-AzureADUser -SearchString $user | select objectId,UserPrincipalName,DisplayName
$user_objectID = $user_search.objectId
$user_principalname = $user_search.UserPrincipalName
$user_displayname = $user_search.displayname
Write-Host ""
Write-Output $user_displayname $user_principalname $user_objectID
Write-Host ""
$user_memberprior=Get-AzureADUserMembership -ObjectId $user_objectID | select DisplayName
#Write-Host "Before User group memebership" -ForegroundColor Yellow
#Write-Output $user_member
#Get-AzureADUserMembership -ObjectId $user_objectID | select DisplayName 



#Adding O365 license to User
$user_license=(Get-MsolUser -UserPrincipalName $user_principalname | select isLicensed).islicensed
#Write-Output $user_license
if ($user_license -eq $false) {
    Write-Host "Assinging O365 license to $user_displayname" -ForegroundColor Green
    Set-MsolUserLicense -UserPrincipalName $user_principalname -AddLicenses "xxxxxxxxxx"
    }
else {
    Write-Host "$user_displayname has O365 license assigned" -ForegroundColor Red
    }



Write-Host ""
$groups=Get-Content C:\temp\group.txt
foreach ($group in $groups)
{
    
    $groupadd=Get-AzureADGroup -SearchString $group | select DisplayName,ObjectID,DirSyncEnabled
    $group_DirSync = $groupadd.DirSyncEnabled
    $group_ObjectID = $groupadd.ObjectId
    $group_member = Get-AzureADGroupMember -ObjectId $group_ObjectID
    $group_memberprincipalname=$group_member.userprincipalname
    if ($group_memberprincipalname -notcontains $user_principalname){
        if ($group_DirSync -eq $true){
            Write-Host "Adding $user_displayname into $group" -ForegroundColor Green
            #AD on-premise
            $user_ad=Get-ADUser -filter * | where {$_.userprincipalname -like $user_principalname}
            $user_samaccountname = $user_ad.SamAccountName
            Add-ADGroupMember -Identity $Group -Members $user_samaccountname
            }
            else {
            #Azure AD
            Write-Host "Adding $user_displayname into $group group" -ForegroundColor Green
            $groupadd=Get-AzureADGroup -SearchString $group | select DisplayName,Objectid
            $group_objectID = $groupadd.objectID
            Add-AzureADGroupMember -ObjectId $group_objectID -RefObjectId $user_objectID
            }
        }
        else { 
            Write-host "$user_displayname already exist in $group" -ForegroundColor Red
            }
}
Write-Host ""
Write-Host "User's membership can be found on C:\temp\User_$($user).txt" -ForegroundColor Cyan
Write-Host ""
$user_memberafter=Get-AzureADUserMembership -ObjectId $user_objectID | select DisplayName

$user_memberprior | Export-Csv C:\temp\User_$($user).txt 
Add-Content C:\temp\User_$($user).txt `n 
Add-Content C:\temp\User_$($user).txt "=====User's Membership After======"
Add-Content C:\temp\User_$($user).txt `n 
$user_memberafter | Export-Csv -Append C:\temp\User_$($user).txt 
@("=====User's membership prior=====") + (Get-Content "C:\temp\User_$($user).txt") | Set-Content C:\temp\User_$($user).txt
