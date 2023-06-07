targetScope = 'subscription'

param identifier string = 'carmlX'
param  resourceGroupNameCore string = 'rg-${identifier}-core'

// Resource Group
module resourceGroup 'ts/artifacts:resources.resourcegroups:latest' = {
  name: '${uniqueString(deployment().name)}-rg'
  params: {
    name: resourceGroupNameCore
  }
}

module userManagedIdentity 'br/overlays:managed-identity.user-assigned-identities:0.4.4' = {
  scope: az.resourceGroup(resourceGroupNameCore)
  name: 'test-managedIdentityOverlay'
  params: {
    name: 'test-managedIdentityOverlay'
  }
  dependsOn: [
    resourceGroup
  ]
}
