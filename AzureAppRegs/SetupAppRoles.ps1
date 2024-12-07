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
        $appSPObjectId = (az ad sp list --display-name $FullAppName --query '[0].id' -o tsv)

        Write-Verbose "App Object Id: $appObjectId"
        Write-Verbose "App Service Principal Object Id: $appSPObjectId"

        if ($null -eq $appObjectId -or $null -eq $appSPObjectId) {
            Write-Host "App registration not found. Skipping..."
            continue;
        }

        $jsonData = Get-Content -Path "./appRoles.json" | ConvertFrom-Json

        # The appRoles file may contain a subset of the roles
        # we will create a unique list of roles already in the app registration and the roles in the file
        Write-Host "Creating unique list of roles to update..."
        $existingAppRegRolesJson = (az ad app list --display-name $FullAppName --query "[0].appRoles")
        Write-Verbose ($existingAppRegRolesJson | ConvertTo-Json)
        $existingAppRegRoles = $existingAppRegRolesJson | ConvertFrom-Json
        $mergedUniqueRoles = $existingAppRegRoles + $jsonData | Sort-Object -Property Id -Unique

        $appRoles = $mergedUniqueRoles | ConvertTo-Json
        Write-Verbose $appRoles

        $appRoles > "./TempRoles.json"

        # Apply the unique set of app roles to the app registration
        Write-Host "Adding app registration roles..."
        az ad app update --id $appObjectId --app-roles "./TempRoles.json"

        # Find existing role assignments in the enterprise app
        $existingRoles = (az rest -m GET -u "https://graph.microsoft.com/v1.0/servicePrincipals/$appSPObjectId/appRoleAssignedTo") | ConvertFrom-Json

        Write-Verbose $existingRoles

        foreach ($role in $jsonData) {
            $existingRole = $existingRoles.value | Where-Object { $_.appRoleId -eq $role.id }

            # No reason to apply an existing role assignment again
            if ($null -ne $existingRole) {
                Write-Verbose $existingRole
                Write-Host "Binding already exist between $($role.Value) and group prefix-$($Env)-$($role.Value)..."
                continue;
            }

            # Find the Azure Entra group using a convention approach of prefix-environment-role
            Write-Host "Binding $($role.Value) to group blog-$($Env)-$($role.Value)..."
            $RoleGuid = $role.id
            $groupId = (az ad group list --display-name "blog-$($Env)-$($role.Value)" --query "[0].id" -o tsv)

            $postBody = "{\""principalId\"": \""$groupId\"", \""resourceId\"": \""$appSPObjectId\"", \""appRoleId\"": \""$RoleGuid\""}"

            Write-Verbose $postBody

            # Create the role assignment between the group and the app role
            az rest -m POST -u "https://graph.microsoft.com/v1.0/servicePrincipals/$appSPObjectId/appRoleAssignments" -b $postBody --headers "Content-Type=application/json"
        }
    }
    
    Write-Host "Finished procesing $($AppName)"
}