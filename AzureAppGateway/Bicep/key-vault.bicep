@description('App Service location. Default is the location of the resource group.')
param location string = resourceGroup().location

@description('App base name')
param appBaseName string = 'fencecloud'

@description('Environment Name.')
param envName string = 'dev'

@description('Web Site name to grant access to.')
param webSiteName string

@description('App gateway user assigned identity for certs.')
param appGatewayIdentity string

var name = toLower('kv-${appBaseName}-${envName}-001')
var skuName = 'standard'
var skuFamily = 'A'

resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: webSiteName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  location: location
  name: name
  tags: {
    project: appBaseName
    environment: envName
  }
  properties: {
    sku: {
      name: skuName
      family: skuFamily
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: appService.identity.principalId
        permissions: {
          secrets: [
            'get', 'list'
          ]
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: appGatewayIdentity
        permissions: {
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    createMode: 'default'
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

output name string = keyVault.name
