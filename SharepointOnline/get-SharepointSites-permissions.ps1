<#PSScriptInfo
.Synopsis
    Gets a list of all Sharepoint sites and permissions and exports to a csv for review
.DESCRIPTION
    Iterates through each site, getting members, both direct and groups.
    Pre-requisite: Account running this script must be assigned as the SiteCollectionAdmin prior, otherwise permission errors will be returned on sites queried.
.NOTES
    Author: tajorgen
    1.0 - 2022-06-06 - Initial release
.PARAMETER SiteURL
    Provide the SharepointURL for one site to generate report for only that one.
.PARAMETER AllSites
    Switch, tells the script to search all sites in the Tenant.
.PARAMETER Domain
    Primary smtp domain used.
    ex: @company.com
.PARAMETER TenantID
    Tenant ID name 
    (get this by visiting portal.office.com and looking at the URL)
#>

param(
    [Parameter(Mandatory=$false)]
    [String]$siteURL,
    [Parameter(Mandatory=$true)]
    [String]$domain,
    [Parameter(Mandatory=$true)]
    [String]$tenantID,
    [Parameter(Mandatory=$false)]
    [Switch]$AllSites
)

#region Functions

#endregion Functions

#region Constants
$scriptDir = $PSScriptRoot
$AdminURL = "https://$($tenantID)-admin.sharepoint.com/"
$csvFilePathGrps = "$($scriptdir)\SPO-permissions-groups.csv"
$csvFilePathUsrs = "$($scriptdir)\SPO-permissions-users.csv"

#endregion Constants

#region Main

#Connect to SharePoint Online (allows MFA-enabled account when not passing credential param)
Connect-SPOService -url $AdminURL

#if the siteURL param passed, get just that one, otherwise retrieve all of the sites in Tenant
if ($siteURL){
    $spoSites = get-sposite -identity $siteURL
}
elseif ($allsites){
    $SPOSites =  Get-SPOSite -limit All    
}
else{
    Write-host "No SiteURL nor AllSites switch provided, exiting script."
    exit
}

#Iterate through each Sharepoint site and get user/group assigned permissions
foreach ($site in $Sposites) {
    #instantiate array to store output
    $arrGroupsData = @()
    $arrUsersData = @()

    write-host "Processing $($spoSites.count) sites..." -foregroundcolor Green
    Write-Host "Processing Site Collection: $($site.URL)" -foregroundcolor Yellow 

    #Get all Groups of the site collection     
    $SiteGroups = Get-SPOSiteGroup -Site $Site.url | Where { $_.Roles -ne $NULL -and $_.Users -ne $NULL}

    #iterate through each permission group for the site
    Write-host "Total Number of Groups Found: $($SiteGroups.Count)"
    Foreach($Group in $SiteGroups) {
        #Add data from groups and members to the array
        $arrGroupsData += New-Object PSObject -Property @{
            'SiteURL' = $site.URL
            'SiteOwner' = $site.Owner
            'GroupName' = $Group.Title
            'Permissions' = $Group.Roles -join ","
            'Users' =  $Group.Users -join ","
        }
    }

    #output groupsdata array to csv
    write-host "Site groups data output to: $($csvFilePathGrps)" -foregroundcolor Green
    $arrGroupsData | Export-Csv -append -NoTypeInformation $csvFilePathGrps

    #Get All users of the site collections and their Groups
    $siteUsers = Get-SPOUser -Site $site.url | Where { $_.loginname -match "@$($domain)"}
    
    Write-host "Total Number of Users Found: $($SiteUsers.Count)"
    foreach ($user in $siteusers) {
        #Add data from spousers of site to array
        $arrUsersData += New-Object PSObject -Property @{
            'SiteURL' = $site.URL
            'UserName' = $user.loginname
            'UserType' = $user.userType
        }
    }
    #output userssdata array to csv
    write-host "Site users data output to: $($csvFilePathUsrs)" -foregroundcolor Green
    $arrUsersData | Export-Csv -append -NoTypeInformation $csvFilePathUsrs

    #clear arrays from memory when complete
    $arrGroupsData.clear()
    $arrUserseData.clear()
}




#endregion Main