@description('App Service location. Default is the location of the resource group.')
param location string = resourceGroup().location

@description('App base name')
param appBaseName string = 'myapp'

@description('Environment Name.')
param envName string = 'dev'

@description('Default FQDN to be used to access MyApp')
param site_FQDN string

@description('User assigned identity for App Gateway')
param identityId string

@description('Key Vault Id to retrieve SSL Certs from')
param keyVaultId string

@description('Key Vault to retrieve SSL Certs from')
param keyVaultCertName string

@description('Custom host name to be used by the web app.')
param webAppCustomHostName string = ''

@description('Error pages base Url. Pages should be named 502.html and 403.html.')
param errorBaseUrl string = ''

@description('Firewal mode')
@allowed([ 'Detection', 'Prevention' ])
param firewallMode string = 'Detection'

var virtualNetworkName = 'vnet-${appBaseName}-${envName}-${location}-001'
var publicIPAddressName = 'pip-${appBaseName}-${envName}-${location}-0010'
var applicationGateWayName = 'apgw-${appBaseName}-${envName}-${location}-001'
var subnet_name = 'App_Gateway_${envName}'
var management_resourcegroup = resourceGroup().name

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnet_name
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

module wafPolicy './app-gateway-policy.bicep' = {
  name: 'wafPolicy'
  params: {
    appBaseName: appBaseName
    envName: envName
    location: location
    firewallMode: firewallMode
  }
}

var splitId = split(keyVaultId, '/')

resource applicationGateWay 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: applicationGateWayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  dependsOn: [
    vnet
    publicIPAddress
    wafPolicy
  ]
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    firewallPolicy: {
      id: wafPolicy.outputs.id
    }
    sslCertificates: [
      {
        name: 'ssl-appgw-external'
        properties: {
          keyVaultSecretId: 'https://${splitId[8]}${environment().suffixes.keyvaultDns}/secrets/${keyVaultCertName}'
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig-${envName}'
        properties: {
          subnet: {
            id: resourceId(management_resourcegroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet_name)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp-${envName}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPAddressName)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'MyApp-BackendPool-${envName}'
        properties: {
          backendAddresses: [
            {
              fqdn: site_FQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'BackendHttpSettings-${envName}'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 600
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGateWayName, 'HttpsHealthProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'MyApp-${envName}-listener-port443'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp-${envName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'port_443')
          }
          protocol: 'Https'
          requireServerNameIndication: false
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGateWayName, 'ssl-appgw-external')
          }
          hostName: webAppCustomHostName
          customErrorConfigurations: !empty(errorBaseUrl) ? [
            {
              statusCode: 'HttpStatus502'
              customErrorPageUrl: '${errorBaseUrl}/502.html'
            }
            {
              statusCode: 'HttpStatus403'
              customErrorPageUrl: '${errorBaseUrl}/403.html'
            }
          ] : []
        }
      }
      {
        name: 'MyApp-${envName}-listener-port80'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp-${envName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false

        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'myRoutingRuleHttps'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'MyApp-${envName}-listener-port443')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'MyApp-BackendPool-${envName}')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'BackendHttpSettings-${envName}')
          }
        }
      }
      {
        name: 'myRoutingRuleHttp'
        properties: {
          ruleType: 'Basic'
          priority: 20
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGateWayName, 'redirectHttpToHttps')
          }
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'MyApp-${envName}-listener-port80')
          }
        }
      }
    ]
    redirectConfigurations: [
      {
        name: 'redirectHttpToHttps'
        properties: {
          redirectType: 'Permanent'
          includePath: true
          includeQueryString: true
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'MyApp-${envName}-listener-port443')
          }
          requestRoutingRules: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules', applicationGateWayName, 'myRoutingRuleHttp')
            }
          ]
        }
      }
    ]
    probes: [
      {
        name: 'HttpsHealthProbe'
        properties: {
          protocol: 'Https'
          host: site_FQDN
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          path: '/health'
        }
      }
    ]
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
}
