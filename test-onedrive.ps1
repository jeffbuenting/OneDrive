Import-Module c:\Scripts\onedrive\onedrive.psm1

$Token = Grant-OneDriveImplicitAuthorization

# ---- Access root of One Drive
#$ApiUri = "https://apis.live.net/v5.0"
#Invoke-RestMethod -Uri "$ApiUri/me/skydrive?access_token=$Token"

# ----- Enumerate child items of root
$ApiUri = "https://apis.live.net/v5.0"
$Root = Invoke-RestMethod -Uri "$ApiUri/me/skydrive?access_token=$Token"
$r = Invoke-RestMethod -Uri "$($Root.upload_location)?access_token=$Token"
$r.data | ft Name, id, upload_location –AutoSize



Close-OneDriveSession