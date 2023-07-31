targetScope = 'subscription'

param location string = 'australiaeast'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'test-rg'
  location: location
}
module userManagedIdentity 'ts/overlays:managed-identity.user-assigned-identities-overlay-remote:1.2' = {
  name: 'test-managedIdentityOverlay'
  scope: az.resourceGroup('test-rg')
  params: {
    name: 'testmiahmnamemi'
  }
  dependsOn: [
    resourceGroup
  ]
}

module storageAccount 'ts/overlays:storage.storage-accounts-overlay-remote:1.0' = {
  name: 'test-storageAccountOverlay'
  scope: az.resourceGroup('test-rg')
  params: {
    name: userManagedIdentity.outputs.name
  }
}
