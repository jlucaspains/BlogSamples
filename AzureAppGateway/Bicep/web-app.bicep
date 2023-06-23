@description('App Service location. Default is the location of the resource group.')
param location string = resourceGroup().location

@description('App base name')
param appBaseName string = 'myapp'

@description('Environment Name.')
param envName string = 'dev'

@description('App Service SKU. Default is F1.')
param sku string = 'B1'

var webSiteName = toLower('app-${appBaseName}-${envName}-${location}-001')
var appServiceName = toLower('asp-${appBaseName}-${envName}-${location}-001')
var linuxFxVersion = 'DOTNETCORE|7.0'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServiceName
  location: location
  tags: {
    project: appBaseName
    environment: envName
  }
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  location: location
  name: webSiteName
  tags: {
    project: appBaseName
    environment: envName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      healthCheckPath: '/health'
      ipSecurityRestrictions: [
        {
          action: 'Allow'
          description: 'Allow Azure services access'
          ipAddress: 'AzureCloud'
          name: 'AzureCloud_access'
          priority: 50
          tag: 'ServiceTag'
        }
      ]
      scmIpSecurityRestrictionsUseMain: true
    }
  }
}

output name string = appService.name
output website_fqdn string = appService.properties.defaultHostName
