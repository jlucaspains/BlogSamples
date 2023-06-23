@description('App Service location. Default is the location of the resource group.')
param location string = resourceGroup().location

@description('App base name')
param appBaseName string = 'myapp'

@description('Environment Name.')
param envName string = 'dev'

var applicationGateWayName = 'apgw-${appBaseName}-${envName}-${location}-001'

resource applicationGateWayUser 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: applicationGateWayName
  location: location
}

output principalId string = applicationGateWayUser.properties.principalId
output resourceId string = applicationGateWayUser.id
