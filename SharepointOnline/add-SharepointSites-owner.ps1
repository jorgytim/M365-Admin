<#PSScriptInfo
.Synopsis
    Gets a list of all Sharepoint sites and permissions and exports to a csv for review
.DESCRIPTION
    Iterates through each site, getting members, both direct and groups
.NOTES
    Author: tajorgen
    1.0 - 2022-06-06 - Initial release
.PARAMETER SiteURL
    The URL of a single sharepoint site to report on.
    Ex: https://<tenantid>.sharepoint.com/sites/suit
.PARAMETER OwnerUPN
    The UPN of the user to assign sitecollectionadmin to
    Ex: username@company.com
.PARAMETER AllSites
    Switch, tells the script to search all sites in the Tenant.
.PARAMETER TenantID
    Tenant ID name 
    (get this by visiting portal.office.com and looking at the URL)
#>

param(
    [Parameter(Mandatory=$false)]
    [String]$siteURL,
    [Parameter(Mandatory=$true)]
    [String]$OwnerUPN,
    [Parameter(Mandatory=$false)]
    [Switch]$AllSites,
    [Parameter(Mandatory=$true)]
    [String]$tenantID,
)

#region Functions

#endregion Functions

#region Constants
$scriptDir = $PSScriptRoot
$AdminURL = "https://$($tenantID)-admin.sharepoint.com/"

#endregion Constants

#region Main
 
#Connect to SharePoint Online, prompt for credentials
Connect-SPOService -url $AdminURL -credential $Credential
 
#if allsites switch param used, get all of the sites in your tenant
if ($AllSites){
    Write-host "Getting all Sharepoint sites in the tenant, this may take a few minutes..."
    $Sites = Get-SPOSite -Limit ALL
}
elseif ($siteURL){
    $Sites = Get-SPOSite -identity $siteURL
}
else{
    Write-host "No SiteURL nor AllSites switch provided, exiting script."
    exit
}

#iterate through sites and add the onwerUPN provided to the site owners
Foreach ($Site in $Sites)
{
    write-host "Processing $($sites.count) sites..." -foregroundcolor Green
    Write-host "Adding $($ownerUPN) to site Collection Admins for: $($Site.URL)" -foregroundcolor Yellow
    Set-SPOUser -site $Site -LoginName $ownerUPN -IsSiteCollectionAdmin $True
}

#endregion Main