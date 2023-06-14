

module userManagedIdentity 'ts/overlays:managed-identity.user-assigned-identities-overlay-remote:1.2' = {
  name: 'test-managedIdentityOverlay'
  params: {
    name: 'testmiahmnamemi'
  }
}



module storageAccount 'ts/overlays:storage.storage-accounts-overlay-remote:1.0' = {
  name: 'test-storageAccountOverlay'
  params: {
    name: userManagedIdentity.outputs.name
  }
}
