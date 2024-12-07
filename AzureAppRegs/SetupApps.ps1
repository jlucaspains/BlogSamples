[CmdletBinding()] param ()

$AppNames = @(
    "OrdersApi",
    "PeopleApi"
)
$Envs = @(
    "dev",
    "qa"
)

foreach ($AppName in $AppNames) {
    Write-Host "Processing $($AppName)..."
    foreach ($Env in $Envs) {
        $FullAppName = "$($AppName)-$($Env)"
        Write-Host "Processing $FullAppName..."
        $appObjectId = (az ad app list --display-name $FullAppName --query "[0].id" -o tsv)

        # If the app is not found, create it.
        # This is the place to add any special configuration needed for a new app registration
        if ($null -eq $appObjectId) {
            $appObjectId = (az ad app create --display-name $FullAppName --sign-in-audience AzureADMyOrg --identifier-uris "api://$($FullAppName).lpains.net" --query "id" -o tsv)
            
            # Ensure the api section is set correctly
            az ad app update --id $appObjectId --set api=@appApi.json
            az ad app permission add --id $appObjectId --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
        }

        # Find the enterprise app service principal object id
        $appSPObjectId = (az ad sp list --display-name $FullAppName --query '[0].id' -o tsv)

        if ($null -eq $appSPObjectId) {
            $appSPObjectId = (az ad sp create --id $appObjectId --query '[0].id' -o tsv)
        }
        # az ad app permission grant --id $appSPObjectId --api 00000003-0000-0000-c000-000000000000 --scope "User.Read"

        Write-Host "App Object Id: $appObjectId"
        Write-Host "App Service Principal Object Id: $appSPObjectId"
    }

    Write-Host "Finished procesing $($AppName). It may take a few minutes for the changes to take effect."
}