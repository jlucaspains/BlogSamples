@description('App Service location. Default is the location of the resource group.')
param location string = resourceGroup().location

@description('Web app host name')
param customHostName string

@description('Web App name')
param appServiceName string

@description('Web App name')
param keyVaultId string

@description('Web App certificate name')
param keyVaultCertificateName string

resource certificate 'Microsoft.Web/certificates@2022-03-01' = {
  name: 'cert-${customHostName}'
  location: location
  properties: {
    keyVaultId: keyVaultId
    keyVaultSecretName: keyVaultCertificateName
  }
}

resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

resource binding 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: customHostName
  parent: appService
  properties: {
    siteName: customHostName
    hostNameType: 'Verified'
    sslState: 'SniEnabled'
    customHostNameDnsRecordType: 'CName'
    thumbprint: certificate.properties.thumbprint
  }
}
