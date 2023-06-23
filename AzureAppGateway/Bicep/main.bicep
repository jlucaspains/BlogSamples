@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Environment Name.')
param envName string = 'dev'

@description('Key vault name containing the ssl certificate.')
param sslCertificateKeyVaultId string = ''

@description('SSL certificate name within the key vault.')
param sslCertificateName string = ''

@description('App Gateway Base url for error pages. Page names must be 403.html and 502.html.')
param apgwErrorBaseUrl string = ''

@description('App Gateway firewal mode')
@allowed([ 'Detection', 'Prevention' ])
param apgwFirewallMode string = 'Detection'

@description('Custom host name to be used by the web app.')
param webAppCustomHostName string = ''

@description('Web App Service SKU. Default is B1.')
param webAppSKU string = 'B1'

var appBaseName = 'myapp'

module webApp './web-app.bicep' = {
  name: 'WebDeployment'
  params: {
    location: location
    appBaseName: appBaseName
    envName: envName
    sku: webAppSKU
  }
}

module keyVault './key-vault.bicep' = {
  name: 'KeyVaultDeployment'
  dependsOn: [
    webApp
  ]
  params: {
    location: location
    appBaseName: appBaseName
    envName: envName
    webSiteName: webApp.outputs.name
    appGatewayIdentity: appGatewayAssignedIdentity.outputs.principalId
  }
}

module appGatewayAssignedIdentity './app-gateway-identity.bicep' = {
  name: 'AppGatewayAssignedIdentityDeployment'
  params: {
    location: location
    appBaseName: appBaseName
    envName: envName
  }
}

module appGateway './app-gateway.bicep' = {
  name: 'AppGatewayDeployment'
  params: {
    site_FQDN: webApp.outputs.website_fqdn
    appBaseName: appBaseName
    envName: envName
    location: location
    identityId: appGatewayAssignedIdentity.outputs.resourceId
    keyVaultId: sslCertificateKeyVaultId
    keyVaultCertName: sslCertificateName
    webAppCustomHostName: webAppCustomHostName
    errorBaseUrl: apgwErrorBaseUrl
    firewallMode: apgwFirewallMode
  }
  dependsOn: [
    keyVault
  ]
}
