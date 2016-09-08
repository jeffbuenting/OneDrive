
Function Get-OneDriveItem {

<#
	.SYNOPSIS
		List items in a One Drive folder

	.DESCRIPTION
		List Items in a One Drive Folder.  Must be already connected to the one drive via connect-OneDrive.

    .Parameter URI
        API URI for One Note.

    .Parameter AccessToke
        Access token to One Note. 

	.Example
		Get-OneDriveItem 

	.Link
		http://blogs.technet.com/b/heyscriptingguy/archive/2013/07/02/use-powershell-to-work-with-skydrive-for-powerful-automation.aspx
#>

	[CmdLetBinding()]
	param( 
        [String]$Uri = "https://apis.live.net/v5.0",

		$AccessToken 
    )
	
    #$ApiUri = "https://apis.live.net/v5.0"

    $Root = Invoke-RestMethod -Uri "$Uri/me/skydrive?access_token=$AccessToken"
    $r = Invoke-RestMethod -Uri "$($Root.upload_location)?access_token=$Token"

    Write-Output $R.data
	
}



Import-Module c:\Scripts\onedrive\onedrive.psm1 -Force

$Token = Connect-OneDrive -clientID 000000004811F237 -Secret 8MEucksFZF99nopu3nw55RHSErU5ejQd -Verbose

# ---- Access root of One Drive
#$ApiUri = "https://apis.live.net/v5.0"
#Invoke-RestMethod -Uri "$ApiUri/me/skydrive?access_token=$Token"

# ----- Enumerate child items of root
#$ApiUri = "https://apis.live.net/v5.0"
#$Root = Invoke-RestMethod -Uri "$ApiUri/me/skydrive?access_token=$Token"
#$r = Invoke-RestMethod -Uri "$($Root.upload_location)?access_token=$Token"
#$r.data | ft Name, id, upload_location –AutoSize

$I = Get-OneDriveItem -AccessToken $Token -Verbose


Close-OneDriveSession -Verbose