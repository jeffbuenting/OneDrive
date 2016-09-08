#-------------------------------------------------------------------------
# Module Onedrive
#-------------------------------------------------------------------------

# ----- One Drive API : http://www.powershellmagazine.com/2014/04/07/using-the-windows-live-apis-from-powershell/

#-------------------------------------------------------------------------
# OneDrive Connection Cmdlets
#-------------------------------------------------------------------------

Function Connect-OneDrive {

<#
    .Synopsis
        Establishes a connection to Microsof One Drive.

    .Description
        Establishes a connection to Microsof One Drive and returns and AccessToken.  This AccessToken is required to access data on One Drive.  Including Files.  And future email, callenders, etc.

        script needs to access user information; so first, the user will need  to sign in and give consent. This is accomblished by hosting a WebBrowser control to direct the user to the Microsoft authorization page. After the user successfully signs in and accepts the scope of information the script can access,  an access token is retrieved by reading the URI that the user is redirected to. More information about this process can be found on the Live SDK Core Concepts site. Depending on the scenario, one of the following OAuth 2.0 grant flows can be used:
			
			•Without Secret password
                Implicit grant flow: ideal for a public environment where explicit user sign-in and consent is required

            •With Secret Password
                Authorization code grant flow: ideal for automation in a safe environment

    .PARAMETER ClientID
		ID of the application as registered with Microsoft.  

        TO DO : Add information on how to get the client ID
 
	.PARAMETER Scope
		Specifies permissions the script has on the One Drive

		ReadOnly	= Read Only  (default)
		Update 		= Read/Write

    .PARAMETER Secret
        Secret password.

        TO DO : Add information on what the Secret password is and where to find it.

    .Example
        Connect to OneDrive automatically

    .Example
        Connect to OneDrive asking the user for username and password

        Grant-OneDriveImplicitAuthorization -ClientID '00000000603E0BFE' -Scope 'Update'

    .Link
		http://blogs.technet.com/b/heyscriptingguy/archive/2013/07/01/use-powershell-3-0-to-get-more-out-of-windows-live.aspx

    .Link
        http://www.powershellmagazine.com/2014/04/07/using-the-windows-live-apis-from-powershell/

#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String]$ClientID,
        
        [ValidateSet( 'ReadOnly','Update' )]
        [String]$Scope = 'ReadOnly',

        [String]$Secret
    )

    $RedirectUri = "https://login.live.com/oauth20_desktop.srf"
	$AuthorizeUri = "https://login.live.com/oauth20_authorize.srf"

	switch ( $Scope ) {
		'ReadOnly' {
				$ScopePermissions = "wl.skydrive"
			}
		'Update' {
				$ScopePermissions = "wl.skydrive_update","wl.signin" -join "%20"
			}
	}

    if ( $Secret ) {
            # ----- Used to Automate
            Write-Verbose "Connect-OneDrive : Code Authorization - Automation"

            Add-Type -AssemblyName System.Windows.Forms
	        $OnDocumentCompleted = {
		        if($web.Url.AbsoluteUri -match "code=([^&]*)") {
			            $script:AuthCode = $Matches[1]
			            $form.Close()
			        }
			        elseif($web.Url.AbsoluteUri -match "error=") {
			            $form.Close()
	          }
	        }

	        $web = new-object System.Windows.Forms.WebBrowser -Property @{Width=400;Height=500}
	        $web.Add_DocumentCompleted($OnDocumentCompleted)
	        $form = new-object System.Windows.Forms.Form -Property @{Width=400;Height=500}
	        $form.Add_Shown({$form.Activate()})
	        $form.Controls.Add($web)

	        # Request Authorization Code
	        $web.Navigate("$AuthorizeUri`?client_id=$ClientID&scope=$ScopePermissions&response_type=code&redirect_uri=$RedirectUri")
	        $null = $form.ShowDialog()

	        # Request AccessToken
	        $Response = Invoke-RestMethod -Uri "https://login.live.com/oauth20_token.srf" -Method Post -ContentType "application/x-www-form-urlencoded" -Body "client_id=$ClientID&redirect_uri=$RedirectUri&client_secret=$Secret&code=$AuthCode&grant_type=authorization_code"
	        $AccessToken = $Response.access_token
	        $ValidThru = (get-date).AddSeconds([int]$Response.expires_in)
	        $RefreshToken = $Response.refresh_token

	        #endregion

	        #Apparently, the previous snippet discloses the client secret, so it should only be used in a secure environment. When the time comes to refresh the access token, another Rest method needs to be called:

	        # Refresh AccessToken
	        $Response = Invoke-RestMethod -Uri "https://login.live.com/oauth20_token.srf" -Method Post -ContentType "application/x-www-form-urlencoded" -Body "client_id=$ClientID&redirect_uri=$RedirectUri&grant_type=refresh_token&refresh_token=$RefreshToken"
	        $AccessToken = $Response.access_token
	        $ValidThru = (get-date).AddSeconds([int]$Response.expires_in)
	        $RefreshToken = $Response.refresh_token

            Write-Verbose $AccessToken
        }
        else {
            # ----- Commonly used in a non secure environment.  A Public computer, etc.
            Write-Verbose "Connect-OneDrive : Implicite Authorization - Asking for username password"

            Add-Type -AssemblyName System.Windows.Forms

	        $OnDocumentCompleted = {
	  	        if($web.Url.AbsoluteUri -match "access_token=([^&]*)") {
			            $script:AccessToken = $Matches[1]
	    		        if($web.Url.AbsoluteUri -match "expires_in=([^&]*)") {
					        $script:ValidThru = (get-date).AddSeconds([int]$Matches[1])
			            }
			            $form.Close()
			          }
			        elseif($web.Url.AbsoluteUri -match "error=") {
			            $form.Close()
		        }
	        }

	        $web = new-object System.Windows.Forms.WebBrowser -Property @{Width=400;Height=500}
	        $web.Add_DocumentCompleted($OnDocumentCompleted)
	        $form = new-object System.Windows.Forms.Form -Property @{Width=400;Height=500}
	        $form.Add_Shown({$form.Activate()})
	        $form.Controls.Add($web)
	        $web.Navigate("$AuthorizeUri`?client_id=$ClientID&scope=$ScopePermissions&response_type=token&redirect_uri=$RedirectUri")

	        $null = $form.ShowDialog()
	
	        Write-Output $AccessToken
    }

}

#-------------------------------------------------------------------------

Function Close-OneDriveSession {

	<#
		.SYNOPSIS
			Closes the One Drive Session
		
        .DESCRIPTION
			 A script should properly sign out a user at the end of a session. Sending the following web request can help ensure that the user’s data isn’t left unattended

        .PARAMETER ClientID
		    ID of the application as registered with Microsoft.  

            TO DO : Add information on how to get the client ID

		.Example
			Close-OneDriveSession -CliendID '00000000603E0BFE'

		.Link
			http://blogs.technet.com/b/heyscriptingguy/archive/2013/07/01/use-powershell-3-0-to-get-more-out-of-windows-live.aspx
	#>

	[CmdLetBinding()]
	param(
        [Parameter(Mandatory = $True)]
        [String]$ClientID
    )

    $RedirectUri = "https://login.live.com/oauth20_desktop.srf"	

	Invoke-WebRequest "https://login.live.com/oauth20_logout.srf?client_id=$ClientID&redirect_uri=$RedirectUri"
}

#-------------------------------------------------------------------------
# Function Get-OneDriveItem
#
# List Items in a folder
#-------------------------------------------------------------------------

