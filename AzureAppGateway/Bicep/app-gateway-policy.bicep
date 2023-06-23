@description('App Service location. Default is the location of the resource group.')
param location string = resourceGroup().location

@description('App base name')
param appBaseName string = 'myapp'

@description('Environment Name.')
param envName string = 'dev'

@description('Firewal mode')
@allowed([ 'Detection', 'Prevention' ])
param firewallMode string = 'Detection'

var applicationGateWayName = 'apgw-${appBaseName}-${envName}-${location}-001'

resource applicationGateWayPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2022-11-01' = {
  name: applicationGateWayName
  location: location
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: firewallMode
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: [
            {
              ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
              rules: [
                {
                  ruleId: '920300'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
          ]
        }
      ]
      exclusions: [
        {
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942450'
                    }
                  ]
                }
              ]
            }
          ]
          matchVariable: 'RequestCookieNames'
          selector: 'myapp_session'
          selectorMatchOperator: 'Equals'
        }
      ]
    }
  }
}

output id string = applicationGateWayPolicy.id
