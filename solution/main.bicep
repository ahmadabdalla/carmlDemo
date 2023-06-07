targetScope = 'subscription'

param identifier string = 'carmldemoX'
param  resourceGroupNameCore string = 'rg-${identifier}-core'

module coreResourceGroup 'childModules/core.bicep' = {
  name: '${uniqueString(deployment().name)}-core'
  params: {
    resourceGroupNameCore: resourceGroupNameCore
  }
}
