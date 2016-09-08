#-------------------------------------------------------------------------
# Module Onedrive
#-------------------------------------------------------------------------


#-------------------------------------------------------------------------
# Function Grant-OneDriveImplicitAuthorization
#
# Implicit grant flow: ideal for a public environment where explicit user sign-in and consent is required
#-------------------------------------------------------------------------

Function Grant-OneDriveImplicitAuthorizaion {

	[CmdLetBinding()]
	param ( [String]$ClientID = "000000004811F237" )

	$RedirectUri = "https://login.live.com/oauth20_desktop.srf"
	$AuthorizeUri = "https://login.live.com/oauth20_authorize.srf"

	$Scope = "wl.skydrive"

	# region - Implicit grant flow

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
	$web.Navigate("$AuthorizeUri`?client_id=$ClientID&scope=$Scope&response_type=token&redirect_uri=$RedirectUri")

	$null = $form.ShowDialog()

	# endregion

}

#-------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------

Export-ModuleMember -Function Grant-OneDriveImplicitAuthorizaion