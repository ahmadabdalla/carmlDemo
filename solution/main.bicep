targetScope = 'subscription'

param identifier string = 'carmldemo'
param  resourceGroupNameCore string = 'rg-${identifier}-core'
param resourceGroupNameWorkload string = 'rg-${identifier}-workload'

@secure()
param virtualMachinePassword string

module coreResourceGroup 'childModules/core.bicep' = {
  name: '${uniqueString(deployment().name)}-core'
  params: {
    resourceGroupNameCore: resourceGroupNameCore
  }
}

module workloadResourceGroup 'childModules/workload.bicep' = {
  name: '${uniqueString(deployment().name)}-workload'
  params: {
    resourceGroupNameWorkload: resourceGroupNameWorkload
    privateDnsZoneKeyVaultResourceId: coreResourceGroup.outputs.privateDnsZoneKeyVaultResourceId
    subnetResourceId: coreResourceGroup.outputs.workloadSubnetResourceId
    virtualMachinePassword: virtualMachinePassword
  }
}
